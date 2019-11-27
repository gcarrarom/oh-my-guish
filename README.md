# oh-my-guish <!-- omit in toc -->

My plugin for oh-my-zsh - functions and aliases


<p align="center">
  <img src="https://github.com/gcarrarom/oh-my-guish/blob/master/render1574821975946.gif">
</p>

## Description <!-- omit in toc -->

This plugin is meant to make my workflow more efficient by adding functions and aliases that make sense for me.
Feel free to use it though :)

## Installation <!-- omit in toc -->

1. Clone the repo to your custom oh-my-zsh plugins:

```git clone https://github.com/gcarrarom/oh-my-guish.git ${ZSH_CUSTOM}/plugins/oh-my-guish``` 

2. Add `oh-my-guish` to your `~/.zshrc` plugins array:
```
plugins=(
    git
    kubectl
    zsh-autosuggestions
    alias-tips
    oh-my-guish
    helm
)
```

## Features <!-- omit in toc -->

Here's the list of features of this ZSH plugin:

- [Functions](#functions)
  - [mkdircd](#mkdircd)
  - [randomdocker](#randomdocker)
  - [Azure](#azure)
    - [azacc](#azacc)
    - [azgroup](#azgroup)
    - [getcredentialsaks](#getcredentialsaks)
    - [getcredentialsaks-admin](#getcredentialsaks-admin)
  - [Kubernetes](#kubernetes)
- [Aliases](#aliases)
  - [Kubernetes](#kubernetes-1)
  - [MacOS](#macos)
    - [lock](#lock)
  - [yoink](#yoink)

### Functions

Commands to make things easier

#### mkdircd
This makes a directory and changes the location of the terminal to it.
#### randomdocker
This function uses the service from Frightanic to generate random names based on Docker's code.
#### Azure
These Azure commands were created to make it easier to navigate through the resources.
##### azacc
This command is going to list all the subscriptions available to your current token, and then use `fzf` to select which one you would like to use
##### azgroup
This command gets all the resource groups from the subscription and lets you select the one you want to be used as default for the subsequent az cli commands. 
use `azgroup all` to reset.
##### getcredentialsaks
This is going to ask for the subscription and resource group of your cluster using `fzf`, then it's going to get your cluster credentials using this command: `az aks get-credentials`

##### getcredentialsaks-admin
This is going to ask for the subscription and resource group of your cluster using `fzf`, then it's going to get your cluster credentials using this command: `az aks get-credentials --admin`


#### Kubernetes


### Aliases

Who wants to type big commands anyways?!

#### Kubernetes
All the aliases that were missing from the default K8s plugin for oh-my-zsh.
To create those aliases I've followed the same pattern as the plugin, so it could feel natural to someone already using it.
This is meant to be an extension rather than substitute the existing k8s plugin.

#### MacOS
These are the aliases specific for MAcOS.
##### lock
This alias locks the computer
#### yoink
This alias sends the file selected to yoink, so you don't have to use the cursor to grab files to yoink.
<p align="center">
  <img src="https://github.com/gcarrarom/oh-my-guish/blob/master/yoinkdemo.gif">
</p>