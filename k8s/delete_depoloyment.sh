#!/bin/bash
set +x

kubectl delete deployment backend-feed
kubectl delete deployment frontend-a
kubectl delete deployment frontend-b
kubectl delete deployment reverseproxy

kubectl delete service backend-feed
kubectl delete service backend-user
kubectl delete service frontend
kubectl delete service reverseproxy
