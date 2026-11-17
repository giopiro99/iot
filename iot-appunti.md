# IoT – appunti revisione progetto di Giovanni

Repo: `~/Desktop/iot` – branch di lavoro **`renato`** (creato da `giovanni` @ `bfce466`, non collegato a nessun branch remoto).
Confronto con: subject v4.1 + evaluation sheet. La correzione si fa sulla VM della 42 (Linux x86).

Legenda: ✅ fatto · ⏳ da decidere/sistemare · 💬 da saper spiegare alla difesa · ✔️ va bene così

---

## Decisioni prese

- **Distro: Ubuntu 22.04 con `box_url` ufficiale** (`cloud-images.ubuntu.com`).
  Ubuntu pubblica il `.box` Vagrant solo per la 22.04 (24.04 e 26.04 hanno solo `.ova`).
  Alternativa scartata per ora: 26.04 costruita con Packer (template di bento).
- **p2: il nome resta `gpirozziS2`.**

---

## Generale (vale per tutte le parti)

- 💬 **IP nella scheda**: il comando `ip a show $(ip route | grep default | awk '{print $5}')` mostra
  `enp0s3` / `10.0.2.15` (NAT di Vagrant), non `.110`. Succede a tutti con Vagrant.
  Spiegare: la prima scheda NAT la crea Vagrant (internet + `vagrant ssh`); il subject chiede
  "a dedicated IP on a **dedicated** network interface" → mostrare `ip a show enp0s8`.
- 💬 **"Latest stable"**: 22.04 → "è l'ultima per cui Ubuntu pubblica ufficialmente una box Vagrant,
  e il subject chiede un `box_url` della distro".
- 💬 **`box_url`**: senza, Vagrant scarica dal registry HashiCorp, che il subject dice non garantito dopo il 2026.
  Il nome box è cambiato in `ubuntu-22.04` così Vagrant non riusa una `ubuntu/jammy64` già in cache.
- ⏳ **Segreti nel repo**: `p1/confs/id_rsa` (chiave privata), `p1/.env` e `p2/.env` (token K3s),
  `bonus/scripts/.env`, `bonus/confs/minio-values.yaml`, `bonus/confs/s3-connection.yaml` (password).
  Non è nella scheda, ma il valutatore legge i file e chiede.
- ⏳ **Test reali**: su Mac (ARM) le box x86 non partono → testare su Linux x86
  (PC di Giovanni via SSH, o una macchina della 42 prima della difesa).

---

## p1

- ✅ `box_url` ufficiale Ubuntu 22.04.
- ✔️ 2 VM, IP `.110`/`.111`, nomi `gpirozziS`/`gpirozziSW`, 1 CPU / 1024 MB, K3s server + agent.
- ⏳ **`kubectl` senza `sudo` non funziona** (permessi su `/etc/rancher/k3s/k3s.yaml`).
  La scheda chiede `kubectl get nodes -o wide` sul server.
  Fix: aggiungere `--write-kubeconfig-mode=644` a `INSTALL_K3S_EXEC` in `p1/scripts/server.sh`.
- ✅ **`agent.sh` stampava il token** (riga `echo "DEBUG-AGENT: ..."`): ora commentata.
- ⏳ `ssh-config.sh`: `chmod 755 ~` gira come root → cambia `/root`, non `/home/vagrant`.
- ⏳ `ssh-config.sh`: `>> authorized_keys` aggiunge duplicati a ogni `vagrant provision`.
- ⚠️ Se un giorno si cambia box: `--flannel-iface=enp0s8` è scritto fisso → verificare il nome con `ip a`.

---

## p2

- ✅ `box_url` ufficiale Ubuntu 22.04.
- ✔️ 1 VM, IP `.110`, 3 app, app2 con 3 repliche, Ingress su Traefik (host app1.com / app2.com / default app3).
  Immagine `nginx:1.31.2` verificata esistente.
- 💬 **Nome `gpirozziS2`**: tenuto. Probabile motivo: VirtualBox non accetta due VM con lo stesso nome
  (la p1 crea già `gpirozziS`). Prepararsi a spiegarlo.
- ⏳ **`kubectl` senza `sudo` non funziona** (stesso problema della p1): la scheda chiede
  `kubectl get nodes -o wide` e `kubectl get all`. Fix: `--write-kubeconfig-mode=644` in `p2/scripts/server.sh`.
- ⏳ **`p2/.env` (token K3s) non serve**: con un solo nodo nessuno deve unirsi al cluster.
  Rimasto dalla p1. Se si toglie, il Vagrantfile usa il default `"token-sviluppo"` e funziona uguale;
  per pulire del tutto togliere anche la lettura del `.env` dal Vagrantfile e `--token` da `server.sh`.
  Se resta: risposta onesta "è rimasto dalla p1".
- 💬 **ConfigMap** (`app*-config.yaml`): contengono l'`index.html` di ogni app, montato in
  `/usr/share/nginx/html` di nginx. Saper spiegare ConfigMap e `volumeMounts`.
- 💬 Ingress: mostrarlo con `kubectl get ingress` e `kubectl describe ingress apps-ingress`.
  Niente `ingressClassName` perché Traefik è il controller di default in K3s.
- 💬 Test: `curl -H "Host: app1.com" 192.168.56.110` / `app2.com` / senza Host → app3.
  Per il browser: `/etc/hosts` sul PC con `192.168.56.110 app1.com` e `192.168.56.110 app2.com`.
- ⏳ (minore) `vb.cpus = 3`, il subject consiglia 1.
- ⏳ (minore) Le 3 repliche di app2 rispondono tutte "app2": col curl non si vede il pod che risponde.
- ⏳ (minore) `kubectl apply` parte appena risponde la porta 6443, senza riprovare.
  Se le app mancano: `sudo kubectl apply -f /var/k3s/`.

---

## p3

- 💬 **Namespace `dev`**: non lo crea lo script, lo crea Argo CD al primo sync
  (`CreateNamespace=true` in `p3/confs/application.yaml`). Se Argo CD non raggiunge GitHub
  (es. problema DNS dalla rete della scuola) `dev` non esiste e `kubectl get ns` mostra solo `argocd`.
  In quel caso crearlo a mano: `kubectl create namespace dev`.
  (Renato invece lo crea nello script, insieme ad `argocd`.)
- ⏳ **Capire il discorso DNS dei commenti** (`p3/scripts/get-argocd.sh` e `p3/scripts/get-docker.sh`).
  Commit di luglio: "p3 non funziona su vagrant" (15/07), "con hotspot l'errore del dns non c'è,
  da capire se a scuola succede o meno" (17/07); nei commenti: "a casa funziona senza, in ufficio
  servivano queste configurazioni". Le due soluzioni (forzano DNS `8.8.8.8`) sono commentate:
  `p3/confs/daemon.json` per Docker, oppure `--volume ...resolv.conf` + `--k3s-arg "--resolv-conf=..."` su `k3d cluster create`.
  Mai provato a scuola. Se a scuola il sync fallisce → `dev` non esiste e la scheda si ferma.
  - Chiedere a Giovanni: l'"ufficio" era la scuola o un'altra rete? Che errore vedeva
    (es. `lookup github.com ... i/o timeout`)? Quale delle due soluzioni funzionava?
  - Provare la p3 **dalla rete della scuola prima di martedì**: `kubectl get application -n argocd`
    (deve essere Synced) e `kubectl get ns` (deve esserci `dev`).
  - Se fallisce, capire a che livello si rompe:
    `nslookup github.com` (VM) →
    `sudo docker run --rm busybox nslookup github.com` (Docker) →
    `kubectl run dnstest -it --rm --image=busybox --restart=Never -- nslookup github.com` (cluster);
    poi riattivare una delle due soluzioni commentate.

- ✔️ **Argo CD** (`p3/confs/application.yaml`): segue `github.com/giopiro99/gpirozzi`, cartella `dev`,
  `targetRevision: HEAD`, sync automatico (`prune` + `selfHeal`) → configurato bene.
- ⏳ **Bug nel repo `gpirozzi`, `dev/app.yaml`**:
  il Service cerca `app.kubernetes.io/name: app`, ma i pod hanno l'etichetta `app: app`.
  - I pod sono `Running` e Argo CD mostra Synced/Healthy → il bug **non si vede** dall'interfaccia.
  - `kubectl get endpoints app-service -n dev` è vuoto → `kubectl port-forward svc/app-service -n dev 8888:8888`
    fallisce → il `curl localhost:8888` della scheda non risponde.
  - Fix (una riga), nel Service:
    ```yaml
    selector:
      app: app
    ```

- ⏳ **Cambio versione v1 → v2 (punto 7 del subject)**: il meccanismo funziona (tag in `gpirozzi/dev/app.yaml`,
  commit + push, sync automatico; Argo CD controlla ogni ~3 min → aspettare o premere Refresh).
  La verifica con `curl localhost:8888` così com'è **non va**:
  - nessuno script apre la porta 8888 → serve, dentro la VM:
    `kubectl port-forward svc/app-service -n dev 8888:8888 --address 0.0.0.0`
    (la scheda dice "accessed **from this machine**": così funziona sia `curl localhost:8888` dentro la VM
    sia `curl http://192.168.56.110:8888/` dal computer della scuola);
  - quel port-forward fallisce finché non si corregge il selector (bug sopra);
  - il repo `gpirozzi` è su **v2** → riportarlo a **v1** prima della difesa.
  - ⚠️ Dopo il passaggio a v2 i pod vengono sostituiti e il port-forward si interrompe
    ("lost connection to pod") → **rilanciarlo** prima del secondo `curl`.

- ⏳ **Argo CD nel browser con login e password** (scheda, Part 3 – Configuration). Così com'è **non va**:
  - `get-argocd.sh` fa `kubectl patch svc argocd-server ... LoadBalancer`, ma in k3d le porte 80/443 del nodo
    sono già prese da Traefik → `EXTERNAL-IP <pending>`; e anche con un IP sarebbe interno a Docker (`172.x`),
    non raggiungibile dal browser del computer della scuola (la VM non ha un browser).
  - Nessuno script mostra la password.
  - **Chiedere a Giovanni se lo sapeva già / come pensava di mostrarlo.**
  - Soluzione a mano alla difesa (dentro la VM):
    `kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0` (terminale aperto),
    password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo`
    → browser sul PC: `https://192.168.56.110:8080`, accettare il certificato auto-firmato, utente `admin`.
    `--address 0.0.0.0` serve perché senza, il port-forward ascolta solo dentro la VM.
  - Alternativa: aggiungere a fine `get-argocd.sh` un `echo` con password e comando del port-forward.
  - Il `patch` a LoadBalancer non serve ma non fa danni.

## Bonus

_(da fare)_

Già notato: Argo CD punta ancora a GitHub, non alla GitLab locale → la scheda non lo valida.
