# Functions
## System

function mkdircd() {
    mkdir $1 && cd $1
}

function randomdocker(){
    curl https://frightanic.com/goodies_content/docker-names.php
}

## K8s

function kdelpn() {
    kgp | grep $1 | cut -d " " -f 1 | xargs -n 1 -I % kubectl delete pod %
}

function old_helm() {
    helm_older_versions_path="$HOME/.helm/older_versions/"
    if [[ ! -d "$helm_older_versions_path" ]]; then
        if [[ ! -d "$HOME/.helm" ]]; then
            mkdir $HOME/.helm
        fi
        mkdir $HOME/.helm/older_versions
    fi
    version="$1"
    older_version_file="$(echo $helm_older_versions_path)helm$version"
    if [[ ! -f "$older_version_file" ]]; then
        curl https://get.helm.sh/helm-v$version-darwin-amd64.tar.gz --output "$older_version_file.tar.gz"
        tar -xvf "$older_version_file.tar.gz" -C $helm_older_versions_path 
        rm -rf "$older_version_file.tar.gz"
        mv "$(echo $helm_older_versions_path)darwin-amd64/helm" $older_version_file
        rm -rf "$(echo $helm_older_versions_path)darwin-amd64"
        chmod +x $older_version_file
    fi
    helm_command=$(echo "$@" | sed s/"$1"//g)
    $older_version_file ${helm_command:1}
}

## Azure

function getresourcegroup() {
    selected_group=$(az configure --list-defaults | jq ".[] | select(.name == \"group\")")
    if [[ -z "$selected_group" ]]; then
        az account set --subscription $(az account list -o json | jq -r '.[].name' | fzf)
        azgroup
        selected_group=$(az configure --list-defaults | jq ".[] | select(.name == \"group\")")
    fi
    echo $selected_group
}

function getclustername() { 
    clusters=$(az aks list -o json)
    if [[ $(echo $clusters | jq ". | length") -gt 1 ]]; then
        clusterName=$(echo $clusters | jq -r '.[].name' | fzf)
    else
        clusterName=$(echo $clusters | jq -r '.[].name')
    fi
    echo $clusterName
}

function getcredentialsaks-admin() {
    getresourcegroup
    clusterName=$(getclustername)
    az aks get-credentials --name $clusterName --admin
}

function getcredentialsaks() {
    getresourcegroup
    clusterName=$(getclustername)
    az aks get-credentials --name $clusterName
}

function azacc() {
    if [[ -z "$1" ]]; then
        az account set --subscription "$(az account list -o json | jq -r '.[].name' | fzf)"
    else
        az account set --subscription "$1"
    fi
    azgroup all
}

function azgroup() {
    if [[ -z "$1" ]]; then
        group=$(az group list -o json | jq -r '.[].name' | fzf)
        az configure --defaults group=$group
    elif [[ "$1" == "all" ]]; then
        az configure --defaults group=
    else
        az configure --defaults group=$1
    fi 
}

# Aliases
## K8s
### Pods
alias kgpall="kubectl get pods --all-namespaces"
alias kgpallwide="kubectl get pods --all-namespaces -o wide"
alias kdelpallns="kubectl get pods | tail +2 | cut -d ' ' -f 1 | xargs -I % -n 1 -P 10 kubectl delete pod %"
alias kgpwatch="watch -d kubectl get pods"
alias kgpwatchwide="watch -d kubectl get pods -o wide"
alias kgpallwatch="watch -d kubectl get pods --all-namespaces"
alias kgpallwatchwide="watch -d kubectl get pods --all-namespaces -o wide"
alias kgpjson="kubectl get pods -o json"

### DaemonSets
alias kgds="kubectl get daemonsets"
alias kgdsall="kubectl get daemonsets --all-namespaces"
alias kdelds="kubectl delete daemonsets "
alias keds="kubectl edit daemonsets "

### Namespace
alias kcns="kubectl create namespace"
alias kgcurrentnamespace="kubectl config get-contexts | grep $(kubectl config current-context) | rev | cut -d ' ' -f 1 | rev"

### Nodes
alias kgnowatch="watch -d kubectl get nodes"
alias kgnowide="kubectl get nodes -o wide"
alias kgnowidewatch="watch -d kubectl get nodes -o wide"

### Services
alias kgswatch="watch -d kubectl get services"
alias kgsall="kubectl get services --all-namespaces"

### Secrets
alias kgsecyaml="kubectl get secret -o yaml"

### Service Accounts
alias kconfigsa="kubectl view-serviceaccount-kubeconfig"
alias kgsa="kubectl get serviceaccounts"
alias kgsaall="kubectl get serviceaccounts --all-namespaces"

### Ingress
alias kgiall="kubectl get ingress --all-namespaces"
alias kgiwatch="watch -d kubectl get ingress"
alias kgiallwatch="watch -d kubectl get ingress --all-namespaces"

### Config Maps
alias kgcm="kubectl get configmaps"
alias kgcmall="kubectl get configmaps --all-namespaces"
alias kecm="kubectl edit configmap"

### Roles
alias kgr="kubectl get roles"
alias kgrall="kubectl get roles --all-namespaces"

### RoleBindings
alias kgrb="kubectl get rolebindings"
alias kgrball="kubectl get rolebindings --all-namespaces"

### Cluster Role Bindings
alias kgcrb="kubectl get clusterrolebindings"
alias kecrb="kubectl edit clusterrolebinding"
alias kccrb="kubectl create clusterrolebinding"
alias kdelcrb="kubectl delete clusterrolebinding"

## Azure
alias aacc="az account show -o json | jq -r '.name'"

## OSX
alias lock="pmset displaysleepnow"

## Yoink
alias yoink="open -g -a Yoink"