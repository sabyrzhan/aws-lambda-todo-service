#!/usr/bin/env bash
action=$1
case $1 in
  apply)
    mvn clean package shade:shade
    cd terraform
    terraform apply -auto-approve
    ;;
  destroy)
    cd terraform
    terraform destroy
    ;;
  *)
    echo 'Invalid command'
    ;;
esac