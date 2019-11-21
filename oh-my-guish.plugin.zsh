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

function helm2.13.1() {
    ~/.helm/older_versions/helm2.13.1 "$@"
}

function helm2.14.3() {
    ~/.helm/older_versions/helm2.14.3 "$@"
}

## Azure

function getcredentialsaks-admin() {
    selected_group=$(az configure --list-defaults | jq ".[] | select(.name == \"group\")")
    if [[ -z "$selected_group" ]]; then
        az account set --subscription $(az account list -o json | jq -r '.[].name' | fzf)
        azgroup
        clusters=$(az aks list -o json)
        if [[ $(echo $clusters | jq ". | length") -gt 1 ]]; then
            clusterName=$(echo $clusters | jq -r '.[] | select(.resourceGroup=="'$resourceGroup'") | .name' | fzf)
        else
            clusterName=$(echo $clusters | jq -r '.[].name')
        fi
        az aks get-credentials --resource-group $resourceGroup --name $clusterName --admin
    else
        clusters=$(az aks list -o json)
        if [[ $(echo $clusters | jq ". | length") -gt 1 ]]; then
            clusterName=$(echo $clusters | jq -r '.[] | select(.resourceGroup=="'$resourceGroup'") | .name' | fzf)
        else
            clusterName=$(echo $clusters | jq -r '.[].name')
        fi
        az aks get-credentials --name $clusterName --admin
    fi
}

function getcredentialsaks() {
    selected_group=$(az configure --list-defaults | jq ".[] | select(.name == \"group\")")
    if [[ -z "$selected_group" ]]; then
        az account set --subscription $(az account list -o json | jq -r '.[].name' | fzf)
        azgroup
        clusters=$(az aks list -o json)
        if [[ $(echo $clusters | jq ". | length") -gt 1 ]]; then
            clusterName=$(echo $clusters | jq -r '.[] | select(.resourceGroup=="'$resourceGroup'") | .name' | fzf)
        else
            clusterName=$(echo $clusters | jq -r '.[].name')
        fi
        az aks get-credentials --resource-group $resourceGroup --name $clusterName
    else
        clusters=$(az aks list -o json)
        if [[ $(echo $clusters | jq ". | length") -gt 1 ]]; then
            clusterName=$(echo $clusters | jq -r '.[] | select(.resourceGroup=="'$resourceGroup'") | .name' | fzf)
        else
            clusterName=$(echo $clusters | jq -r '.[].name')
        fi
        az aks get-credentials --name $clusterName
    fi
}

function azacc() {
    az account set --subscription "$(az account list -o json | jq -r '.[].name' | fzf)"
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