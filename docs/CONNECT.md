# Connectivity Debugging

## Metallb L2 announcing

```
# From the talos node (netshoot on hostnetwork) performing the announce (see svc events by metallb)
talos-wrk2:~# tcpdump -eni ens18.30 'arp and host 192.168.30.100'
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on ens18.30, link-type EN10MB (Ethernet), snapshot length 262144 bytes
08:19:16.542294 c8:7f:54:e4:f2:18 > ff:ff:ff:ff:ff:ff, ethertype ARP (0x0806), length 56: Request who-has 192.168.30.100 tell 192.168.30.1, length 42
08:19:16.542408 bc:24:11:f7:7e:13 > c8:7f:54:e4:f2:18, ethertype ARP (0x0806), length 60: Reply 192.168.30.100 is-at bc:24:11:f7:7e:13, length 46

# From the router
adm820@RT-AX88U_Pro-F218:/tmp/home/root# ip neigh flush 192.168.30.100 dev br30
adm820@RT-AX88U_Pro-F218:/tmp/home/root# ping -c 1 192.168.30.100
PING 192.168.30.100 (192.168.30.100): 56 data bytes

--- 192.168.30.100 ping statistics ---
1 packets transmitted, 0 packets received, 100% packet loss
```

## Debug https connect from workstation to Talos node


---
Dat de SYN met bron `192.168.30.1` binnenkomt, bewijst dat SNAT werkt. Dat er nergens een SYNACK uitgaat, zelfs niet op `-i any`, betekent dat het pakket op de node sneuvelt voordat er een antwoord bestaat. Of de pod antwoordt niet. Ik kan vanaf hier niet zien welke van de twee het is, dus ik loop het pad stap voor stap na.

## Eén kanttekening bij je `-i any` capture

De SYNACK komt van de pod (`10.244.x.x`). Het VIP als bron verschijnt pas na de un-DNAT, vlak voordat het pakket de node verlaat. Als het antwoord wel bestaat maar ergens vastloopt, zie je het met jouw filter dus ook niet. Filter daarom breder op de client:

```bash
tcpdump -nni any host 192.168.30.1 and tcp port 443
```

Hiermee zie je op welke interface het SYN na de DNAT doorgestuurd wordt (`cali*` of `vxlan.calico`, bestemming `10.244.x.x`) en of er een antwoord terugkomt.

## Controles op de node (netshoot, hostnetwork)

```bash
# 1. Wordt er gedropt door reverse path filtering?
sysctl net.ipv4.conf.all.rp_filter net.ipv4.conf.default.rp_filter net.ipv4.conf.ens18/30.rp_filter
nstat -az | grep -i IPReversePathFilter     # teller laten oplopen tijdens curl?

# 2. Is er een conntrack-entry (is er gedNAT't)?
conntrack -L 2>/dev/null | grep 192.168.30.1

# 3. Waar draait de pod, en zijn er endpoints?
kubectl -n istio-gateway get endpointslices
kubectl -n istio-gateway get pods -o wide
kubectl -n istio-gateway get svc public-ingressgateway -o yaml | grep -i trafficpolicy
```

Hoe je de uitkomst leest:

- **`IPReversePathFilter` loopt op**: rp_filter is de boosdoener. Zet `net.ipv4.conf.all.rp_filter` en `default` op `"2"` in `machine.sysctls`. Dit is een goede verdachte, omdat je rp_filter nog niet had aangepast. Met jouw policy rules kan de reverse-path-lookup bovendien per bronadres anders uitpakken. Dat zou ook verklaren waarom het eerder met de `dst`-rule wél werkte.
- **Geen conntrack-entry**: het pakket wordt gedropt vóór of tijdens PREROUTING. Dan kijk je naar rp_filter of de Calico/kube-proxy-regels.
- **Wel een conntrack-entry met `[UNREPLIED]`**: de DNAT werkt, maar de pod of het pad naar de pod antwoordt niet. Is de pod op een andere node, dan loopt het via VXLAN. Controleer dan op `ens18.20` of UDP/4789 heen en terug gaat.
- **`externalTrafficPolicy: Local` en de pod staat niet op wrk2**: dan dropt de node het verkeer bewust, en dat is geen netwerkfout.

## Als bovenstaande niets oplevert

Je kunt per hook zien waar het pakket verdwijnt:

```bash
nft monitor trace    # na een 'nft add rule' met meta nftrace set 1, of kijk naar de drop-tellers:
nft list ruleset | grep -iE 'drop|reject' | head -30
```

Plak de output van `sysctl`/`nstat`, de conntrack-regel en de `tcpdump -i any host 192.168.30.1`. Daarmee kunnen we vaststellen op welke stap het pakket verdwijnt.

---

rp_filter is uitgesloten (alles `0`, teller `0`), dus die verdenking was fout. Mijn vorige capture-filter was bovendien te smal, en dat verbergt waarschijnlijk de echte oorzaak.

## Waarschijnlijke oorzaak: rule 1000 kaapt het doorgestuurde pakket

De volgorde op de node is:

1. SYN komt binnen: `192.168.30.1 → 192.168.30.100:443`.
2. DNAT naar de pod: `192.168.30.1 → 10.244.252.66:8443`. De pod staat op **wrk3**, dus het pakket moet via VXLAN.
3. **Routekeuze.** Het bronadres is hier nog `192.168.30.1`, want de masquerade volgt pas in POSTROUTING.
4. Rule `1000: from 192.168.30.0/24 lookup 30` matcht en table 30 heeft een default route via `192.168.30.1 dev ens18.30`.

Het pakket gaat dus niet naar `vxlan.calico`, maar wordt via `ens18.30` terug naar de router gestuurd. Dat verklaart ook waarom het eerder met client `192.168.50.88` wél werkte: die matchte rule 1000 niet. Het verklaart ook waarom je niets zag. Na de DNAT is de poort **8443**, dus je filter `tcp port 443` liet precies dat pakket weg.

Dit is nog een hypothese, maar hij past bij alles wat je tot nu toe liet zien. Controleer het zo, zonder poortfilter:

```bash
tcpdump -nni any host 192.168.30.1
ip route get 10.244.252.66 from 192.168.30.1 iif ens18.30
```

Mijn voorspelling: je ziet `192.168.30.1 > 10.244.252.66.8443` uitgaan op `ens18.30`, en `ip route get` zegt `dev ens18.30 via 192.168.30.1` in plaats van `vxlan.calico`.

## Fix

Met SNAT op de router is de policy rule overbodig. Het bronadres is nu `192.168.30.1`, dat zit in hetzelfde subnet als `ens18.30`, en de connected route in de main table regelt de reply. Verwijder dus `RoutingRuleConfig` `"1000"` (en de oude `dst`-rule `"999"` als die er nog staat) uit je machine config en pas toe. Daarna:

```bash
ip rule show        # alleen local / main / default
curl -vk --connect-timeout 5 --resolve grafana.dev.bigbang.mil:443:192.168.30.100 https://grafana.dev.bigbang.mil/
```

Wil je het eerst snel testen: `ip rule del priority 1000` vanuit de netshoot-pod. Talos kan de rule bij een reconcile weer terugzetten, dus pas het daarna ook in de config aan.

## Let op bij je plan voor VLAN20

Dezelfde val ligt in de `src`-rule `900` (`192.168.20.0/24 → table 20`). Verkeer van een andere node dat naar een pod wordt gedNAT't heeft op het moment van de routekeuze nog een `192.168.20.x`-bron, en table 20 kent geen pod- of VXLAN-routes. Dat kan pod-verkeer tussen nodes breken. Als je hem toch wilt, test dat dan eerst op één worker, bijvoorbeeld met `--mode=try`. Een veiliger alternatief is de VLAN20-default simpelweg een lagere metric geven dan `ens18` en de rule weglaten.

## Over je lege conntrack-output

Die gebruikte `2>/dev/null`, dus een falende `conntrack`-tool zou er hetzelfde uitzien. Draai hem zonder die redirect, terwijl je curlt. Is er na de fix nog steeds geen entry voor `192.168.30.1`, dan ligt het probleem eerder in de keten en kijken we verder naar de Calico/kube-proxy-regels.

Laat de output van `tcpdump -nni any host 192.168.30.1` en `ip route get 10.244.252.66 from 192.168.30.1 iif ens18.30` zien als je dit eerst wilt bevestigen.
```
