#!/bin/bash

set -e

##Extract the base64 encoded config data and write this to the KUBECONFIG
if [ ! -z "$KUBE_CONFIG_DATA" ]
then
  mkdir -p ${HOME}/.kube
  echo "$KUBE_CONFIG_DATA" | base64 --decode > ${HOME}/.kube/config
  export KUBECONFIG=${HOME}/.kube/config
fi 

##Setup AWS credentials if provided
if [[ ! -z $AWS_ACCESS_KEY_ID ]] && [[ ! -z $AWS_SECRET_ACCESS_KEY ]] && [[ ! -z $AWS_DEFAULT_REGION ]]
then 
  aws configure set default.region ${AWS_DEFAULT_REGION}
  aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
  aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
fi

# Set default values for experiment configuration
EXPERIMENT_IMAGE=${EXPERIMENT_IMAGE:-"litmuschaos/go-runner"}
EXPERIMENT_IMAGE_TAG=${EXPERIMENT_IMAGE_TAG:-"3.18.0"}
TOTAL_CHAOS_DURATION=${TOTAL_CHAOS_DURATION:-60}

# Handle Litmus installation if requested
if [ "$INSTALL_LITMUS" = "true" ]; then
  echo "Installing Litmus..."
  /app/install-litmus
fi

# Handle Litmus cleanup if requested and no experiment is specified
if [ "$LITMUS_CLEANUP" = "true" ] && [ -z "$EXPERIMENT_NAME" ]; then
  echo "Cleaning up Litmus..."
  /app/uninstall-litmus
  exit 0
fi

# Map experiment names to their corresponding scripts in chaos-ci-lib
case "$EXPERIMENT_NAME" in
  "pod-delete")
    /app/pod-delete
    ;;
  "container-kill")
    /app/container-kill
    ;;
  "pod-cpu-hog")
    /app/pod-cpu-hog
    ;;
  "pod-memory-hog")
    /app/pod-memory-hog
    ;;
  "node-cpu-hog")
    /app/node-cpu-hog
    ;;
  "node-memory-hog")
    /app/node-memory-hog
    ;;
  "node-io-stress")
    /app/node-io-stress
    ;;
  "disk-fill")
    /app/disk-fill
    ;;
  "pod-network-latency")
    /app/pod-network-latency
    ;;
  "pod-network-loss")
    /app/pod-network-loss
    ;;
  "pod-network-corruption")
    /app/pod-network-corruption
    ;;
  "pod-network-duplication")
    /app/pod-network-duplication
    ;;
  "pod-autoscaler")
    /app/pod-autoscaler
    ;;
  "all")
    /app/all-experiments
    ;;
  *)
    echo "Unknown experiment: $EXPERIMENT_NAME"
    echo "Available experiments: pod-delete, container-kill, pod-cpu-hog, pod-memory-hog, node-cpu-hog, node-memory-hog, node-io-stress, disk-fill, pod-network-latency, pod-network-loss, pod-network-corruption, pod-network-duplication, pod-autoscaler, all"
    exit 1
    ;;
esac

# Handle Litmus cleanup after experiment if requested
if [ "$LITMUS_CLEANUP" = "true" ] && [ ! -z "$EXPERIMENT_NAME" ]; then
  echo "Cleaning up Litmus after experiment..."
  /app/uninstall-litmus
fi
