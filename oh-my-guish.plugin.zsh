# Functions

function lbuild() {
    python3 ../SwaggerCodegen/buildScripts/build.py local --microservice_name ${1%_SERVER/}; 
}

## Python

function piprequires() {    
    if [[ -z "$1" ]]; then
        echo "You are missing the package name!"
    else
        pip3 index versions $1 | grep LATEST | cut -d ":" -f 2 | tr -s " " | cut -d " " -f 2 | xargs -n1 -I % curl https://pypi.org/pypi/$1/%/json | jq '.info.requires_dist'
    fi
}

## Git

function grw() {
    git reset $(glc)
}

function glc() {
    if [[ -z "$1" ]]; then
        git log --oneline | head -n 2 | tail +2 | cut -d " " -f 1
    else
        git log --oneline | head -n $((2+$1)) | tail +$((2+$1)) | cut -d " " -f 1
    fi
}

## Docker

function docker_build_run() {
    buildoutput=$(docker build .)
    echo $buildoutput | tail -1 | cut -d " " -f 3 | xargs -n 1 -I % docker run -p 8080:80 %
}

## Math

function avg() {
    if (( $# == 0 )) ; then
        array=$(cat)
    else
        array=$@
    fi
    count=0
    total=0
    IFS=$'\n'; arr=( $(echo -e "$array") );for i in ${arr[@]};
    do
        total=$(echo $total+$i | bc )
        ((count++))
    done
    echo "scale=2; $total / $count" | bc
}

function math_sum(){
    if (( $# == 0 )) ; then
        array=$(cat)
    else
        array=$@
    fi
    total=0
    IFS=$'\n'; arr=( $(echo -e "$array") );for i in ${arr[@]};
    do
        total=$(echo $total+$i | bc )
    done
    echo $total 
}

## System

function kill_group() {
    ps -eo pgid,command | grep $1 | head -n 1 | sed  -r 's/^([^.]+).*$/\1/; s/^[^0-9]*([0-9]+).*$/\1/' | xargs -I % kill -9 -%
}

function mkdircd() {
    mkdir $1 && cd $1
}

function randomdocker(){
    curl https://frightanic.com/goodies_content/docker-names.php
}

function moveallup(){
    for file in $(ls)
    do
        if [[ ! -f $file ]]; then
            mv ./$file/*.* ./
        fi
    done 
}

## K8s

function kreportns() {
    toppodsresults=$(ktp | tail +2 | tr -s " ")

    avgcpu=$(echo $toppodsresults | cut -d " " -f 2 | cut -d "m" -f 1 | avg)
    totalcpu=$(echo $toppodsresults | cut -d " " -f 2 | cut -d "m" -f 1 | math_sum)
    avgmem=$(echo $toppodsresults | cut -d " " -f 3 | cut -d "M" -f 1 | avg)
    totalmem=$(echo $toppodsresults | cut -d " " -f 3 | cut -d "M" -f 1 | math_sum)

    echo "
    NS TOTAL USAGE:
    Memory (MB) = $totalmem
    CPU (mCPU)  = $totalcpu

    NS AVG USAGE:
    Memory (MB) = $avgmem
    CPU (mCPU)  = $avgcpu
    "
}

function kreport() {
    # getting data from K8s
    topnoderesults=$(ktopno | tail +2 | tr -s " ")
    allpods=$(kgpall | tail +2)
    nodeinformation=$(kgno -o json)

    # transforming data
    numallpods=$(echo $allpods | wc -l)
    numsystempods=$(echo $allpods | grep kube-system | wc -l)
    numpodsnotsystem=$(echo $allpods | grep -v kube-system | wc -l)
    cpupercent=$(echo $topnoderesults | cut -d " " -f 3 | cut -d "%" -f 1 | avg)
    mempercent=$(echo $topnoderesults | cut -d " " -f 5 | cut -d "%" -f 1 | avg)
    cpunum=$(echo $topnoderesults | cut -d " " -f 2 | cut -d "m" -f 1 | avg)
    memnum=$(echo $topnoderesults | cut -d " " -f 4 | cut -d "M" -f 1 | avg)
    totalcpu=$(echo $nodeinformation | jq -r '.items[].status.capacity.cpu' | math_sum)
    totalmemory=$(echo "$(echo $nodeinformation | jq -r '.items[].status.capacity.memory' | cut -d 'K' -f 1 | math_sum) /(1024*1024)"| bc)
    numnodes=$(echo $topnoderesults | wc -l)
    cpuinuse=$(echo "$totalcpu * $cpupercent / 100" | bc)
    mcpuinuse=$(echo "$totalcpu * 1000 * $cpupercent / 100" | bc)
    memoryinuse=$(echo "$totalmemory * $mempercent / 100" | bc)
    memoryinusemb=$(echo "$totalmemory * 1024 * $mempercent / 100" | bc)

    # output
    echo "
    #all pods:              $numallpods
    #pods in kube-system:   $numsystempods
    #pods elsewhere:        $numpodsnotsystem
    #nodes:                 $numnodes

    Total CPU:              $totalcpu
    Total Memory(GB):       $totalmemory
    CPU per Node:           $(echo $totalcpu / $numnodes | bc)
    Memory per Node:        $(echo $totalmemory / $numnodes | bc)

    CPU in use:             $cpuinuse
    Memory in use(GB):      $memoryinuse

    mCPU/POD:               $(echo $mcpuinuse / $numallpods | bc)
    Memory(MB)/POD:         $(echo $memoryinusemb / $numallpods | bc)

    CPU avg(m cpu): $cpunum = $cpupercent%
    RAM avg(MB): $memnum = $mempercent%"
}

_encode() {
    local _length="${#1}"
    for (( _offset = 0 ; _offset < _length ; _offset++ )); do
        _print_offset="${1:_offset:1}"
        case "${_print_offset}" in
            [a-zA-Z0-9.~_-]) printf "${_print_offset}" ;;
            '/') printf '/' ;;
            ':') printf ':' ;;
            *) printf '%%%X' "'${_print_offset}" ;;
        esac
    done
}

function holog() {
    since=$1
    if [[ -z "$since" ]]; then
        since="10m"
    fi
    hopod=$(kubectl get pods --all-namespaces | tr -s " " | cut -d " " -f 2 | grep helm-operator)
    if [[ ! -z "$hopod" ]]; then
        hons=$(kubectl get pods --all-namespaces | grep $hopod | cut -d " " -f 1)
        kubectl logs -f $hopod -n $hons --since $since
    else
        echo "Helm Operator pod not found! ◉_◉"
    fi

}

function kshell() {
    kubectl run oh-my-guish-pod -it --rm --image $1
}

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
    printf -v arguments_for_command ' %s' "${helm_command[@]}"
    $older_version_file ${arguments_for_command:1}
}

## Flux

function flw(){
    flux_configuration_path="$HOME/.flux/"
    flux_configuration_file_name="config"
    namespace_selected=$1
    if [[ ! -d "$flux_configuration_path" ]]; then
        mkdir $flux_configuration_path
    fi
    if [[ ! -f "$flux_configuration_path$flux_configuration_file_name" ]]; then
        touch $flux_configuration_path$flux_configuration_file_name
        echo "{}" > $flux_configuration_path$flux_configuration_file_name
    fi
    configuration=$(cat $flux_configuration_path$flux_configuration_file_name)
    if [[ -z "$namespace_selected" ]]; then
        namespace_selected=$(echo $configuration | jq -r ".namespace")
        if [[ -z "$namespace_selected" ]]; then
            fluxctl list-workloads -n $(kubectl config get-contexts | grep $(kubectl config current-context) | rev | cut -d ' ' -f 1 | rev)
        else
            fluxctl --k8s-fwd-ns $namespace_selected list-workloads -n $(kubectl config get-contexts | grep $(kubectl config current-context) | rev | cut -d ' ' -f 1 | rev)
        fi
    else
        fluxctl --k8s-fwd-ns $namespace_selected list-workloads -n $(kubectl config get-contexts | grep $(kubectl config current-context) | rev | cut -d ' ' -f 1 | rev)
    fi

}

function flwall(){
    flux_configuration_path="$HOME/.flux/"
    flux_configuration_file_name="config"
    namespace_selected=$1
    if [[ ! -d "$flux_configuration_path" ]]; then
        mkdir $flux_configuration_path
    fi
    if [[ ! -f "$flux_configuration_path$flux_configuration_file_name" ]]; then
        touch $flux_configuration_path$flux_configuration_file_name
        echo "{}" > $flux_configuration_path$flux_configuration_file_name
    fi
    configuration=$(cat $flux_configuration_path$flux_configuration_file_name)
    if [[ -z "$namespace_selected" ]]; then
        namespace_selected=$(echo $configuration | jq -r ".namespace")
        if [[ -z "$namespace_selected" ]]; then
            fluxctl list-workloads --all-namespaces
        else
            fluxctl --k8s-fwd-ns $namespace_selected list-workloads --all-namespaces
        fi
    else
        fluxctl --k8s-fwd-ns $namespace_selected list-workloads --all-namespaces
    fi

}

function fsync(){
    flux_configuration_path="$HOME/.flux/"
    flux_configuration_file_name="config"
    namespace_selected=$1
    if [[ ! -d "$flux_configuration_path" ]]; then
        mkdir $flux_configuration_path
    fi
    if [[ ! -f "$flux_configuration_path$flux_configuration_file_name" ]]; then
        touch $flux_configuration_path$flux_configuration_file_name
        echo "{}" > $flux_configuration_path$flux_configuration_file_name
    fi
    configuration=$(cat $flux_configuration_path$flux_configuration_file_name)
    if [[ -z "$namespace_selected" ]]; then
        namespace_selected=$(echo $configuration | jq -r ".namespace")
        if [[ -z "$namespace_selected" ]]; then
            fluxctl sync
        else
            fluxctl --k8s-fwd-ns $namespace_selected sync
        fi
    else
        fluxctl --k8s-fwd-ns $namespace_selected sync
    fi
}

function fluxns(){
    flux_configuration_path="$HOME/.flux/"
    flux_configuration_file_name="config"
    namespace_selected=$1
    if [[ ! -d "$flux_configuration_path" ]]; then
        mkdir $flux_configuration_path
    fi
    if [[ ! -f "$flux_configuration_path$flux_configuration_file_name" ]]; then
        touch $flux_configuration_path$flux_configuration_file_name
        echo "{}" > $flux_configuration_path$flux_configuration_file_name
    fi
    configuration=$(cat $flux_configuration_path$flux_configuration_file_name)
    if [[ -z "$namespace_selected" ]]; then
        namespace_selected=$(kubectl get namespaces | cut -d " " -f 1 | tail +2 | fzf)
    fi
    if [[ -z "$namespace_selected" ]]; then
        echo "no namespace selected!"
    else
        echo $configuration | jq ".namespace = \"$namespace_selected\"" > $flux_configuration_path$flux_configuration_file_name
        FLUX_FORWARD_NAMESPACE=$namespace_selected
    fi
}

## Azure

function clone_aad_group_memberships() {
    unset error
    if [[ ! -z "$1" ]]; then
        user_from="$1"
    else
        echo "The user you're cloning from cannot be empty!"
        error=1
    fi
    if [[ ! -z "$2" ]]; then
        user_to="$2"
    else
        echo "The user you're cloning to cannot be empty!"
        error=2
    fi

    if [[ ! -z "$error" ]]; then
        return $error
    fi

    echo "Searching for user $user_from"
    user_from_id=$(az ad user show --id "$user_from" | jq -r ".objectId")
    if [[ -z "$user_from_id" ]]; then
        echo "User $user_from not found in AAD!"
        return 1
    fi
    echo "Searching for user $user_to"
    user_to_id=$(az ad user show --id "$user_to" | jq -r ".objectId")
    if [[ -z "$user_to_id" ]]; then
        echo "User $user_to not found in AAD!"
        return 1
    fi

    groups_ids=($(az ad user get-member-groups --id $user_from_id | jq -r '.[].objectId'))
    group_count=0
    echo "Adding $user_to to ${#groups_ids[@]} groups"
    for group_id in $groups_ids; do
        group_count=$(echo "$group_count + 1" | bc)
        printf "Adding.... ($group_count/${#groups_ids[@]})\r"
        az ad group member add --group $group_id --member-id $user_to_id
    done

}

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

## numi

function numi() {
    if [[ "$@" == "open" ]]; then 
        open -a numi
    elif [[ $# == 0 ]] ; then
        while read -r data ; do
            numi "${data}"
        done
    else
        data=$@
        curl -G --data-urlencode "q=$data" http://localhost:15055
        echo ""
    fi
}


# Aliases

## Abak https://github.com/gcarrarom/fancy-abak
if [[ -z "$OHMYGUISH_ABAK_IGNORE" ]]; then
    alias a='abak'
    alias atl="a timesheet list"
    alias atlprevious="atl --previous"
    alias atltotal='atl --show-totals'
    alias atltotalprevious='atl --show-totals --previous'
    alias atlprevioustotal='atl --show-totals --previous'
    alias atlid='atl --show-id'
    alias ats="a timesheet set"
    alias atd="a timesheet delete"
    alias ata="a timesheet approve"
    alias acs='a context select'
fi

## Numi
alias n="numi"

## Python
alias pip="pip3"
alias python="python3"

## Helm
alias hls="helm list"
alias hlsall="helm list --all-namespaces"

## Jiractl - https://github.com/gcarrarom/fancy-jira

if ! $OHMYGUISH_JIRA_IGNORE; then
    alias jgi="jira get issues"

    alias jci="jira create issue"
    alias jcc="jira create comment"

    alias jui="jira update issue"

    alias jconfig="jira config show"
    alias jconfigs="jira config set"
    alias jconfigr="jira config remove"
fi

## K8s
### Pods
alias kgpall="kubectl get pods --all-namespaces"
alias kgpallwide="kubectl get pods --all-namespaces -o wide"
alias kdelpall="kubectl delete pods --all"
alias kgpwatch="watch -d kubectl get pods"
alias kgpwatchwide="watch -d kubectl get pods -o wide"
alias kgpallwatch="watch -d kubectl get pods --all-namespaces"
alias kgpallwatchwide="watch -d kubectl get pods --all-namespaces -o wide"
alias kgpjson="kubectl get pods -o json"
alias ktp="kubectl top pods"
alias ktpwatch="watch -d kubectl top pods"
alias kpop="echo \"\nHere are your pods, m'lady...\n*Tips Fedora*\n(♡-_-♡)\n\n\" && kgp && echo \"\nヽ(♡‿♡)ノ\""

### CC - Kubernetes Operator for cluster configuration - not open source yet.
if $OHMYGUISH_CLUSTERCONFIGURATOR_ENABLE; then
    alias kgcc="kubectl get cc"
    alias kgccall="kubectl get cc --all-namespaces"
    alias kdcc="kubectl describe cc"
    alias kdelcc="kubectl delete cc"
    alias kecc="kubectl edit cc"
fi


### HelmReleases
alias kghr="kubectl get hr"
alias kghrall="kubectl get hr --all-namespaces"
alias kdhr="kubectl describe hr"
alias kdelhr="kubectl delete hr"
alias kehr="kubectl edit hr"
alias kgh="kubectl get helmreleases"
alias kghall="kubectl get helmreleases --all-namespaces"
alias kghallwatch="watch -d kubectl get helmreleases --all-namespaces"
alias kghwatchall="watch -d kubectl get helmreleases --all-namespaces"
alias kghwatch="watch -d kubectl get helmreleases"

### DaemonSets
alias kgds="kubectl get daemonsets"
alias kgdsall="kubectl get daemonsets --all-namespaces"
alias kdelds="kubectl delete daemonsets "
alias keds="kubectl edit daemonsets "

### Namespace
alias kcns="kubectl create namespace"
alias kgcurrentnamespace="kubectl config get-contexts | grep $(kubectl config current-context) | rev | cut -d ' ' -f 1 | rev"
alias kgnswatch="watch -d kubectl get namespaces"

### Deployments
alias kgdall="kubectl get deployments --all-namespaces"
alias kgdwatchall="watch -d kubectl get deployments --all-namespaces"
alias kgdallwatch="watch -d kubectl get deployments --all-namespaces"
alias kgdwatch="watch -d kubectl get deployments"

### Nodes
alias kgnowatch="watch -d kubectl get nodes"
alias kgnowide="kubectl get nodes -o wide"
alias kgnowidewatch="watch -d kubectl get nodes -o wide"
alias ktopno="kubectl top nodes"
alias ktopnowatch="watch -d kubectl top nodes"

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

### Events
alias kge="kubectl get events --sort-by='.metadata.creationTimestamp'"

## Azure
alias aacc="az account show -o json | jq -r '.name'"

## OSX
alias lock="pmset displaysleepnow"

## System
if command -v gping; then alias ping="gping"; fi > /dev/null
alias please="sudo"

#pbcopy/paste on linux
if command apt > /dev/null; then
    alias pbcopy='xsel --clipboard --input'
    alias pbpaste='xsel --clipboard --output'
fi

alias copy_last_command="fc -ln -1 | pbcopy"
alias reload="source ~/.zshrc"

## Yoink
alias yoink="open -g -a Yoink"

## thefuck - https://github.com/nvbn/thefuck
if command -v fuck; then alias sorry="fuck"; fi > /dev/null

## Terminal
### Colors
Color_Off='\033[0m'       # Text Reset

### Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

### Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

### Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

### Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

### High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

### Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

### High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White