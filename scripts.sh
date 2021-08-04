
#ssh to your server
#***********************************************variables*********************************************
declare UI_POD_NAME;
declare BUS_POD_NAME;
declare DB_POD_NAME;
declare ProductsUIClusterIP;
declare ProductsBusinessClusterIP;
declare ProductsDBClusterIP;
declare POD_BUSINESS_STAGE_NS;
declare POD_UI_STAGE_N;
declare  UI_POD_NAM;
declare  BUS_POD_NAME;
declare  DB_POD_NAME;

function setup_env(){
 

    kubectl create namespace products-prod 
    kubectl create namespace products-stage 

    #Deploy PODs to products-prod name space
    kubectl create deployment products-ui -n products-prod --image=gcr.io/google-samples/hello-app:1.0 
    kubectl create deployment products-business -n products-prod --image=gcr.io/google-samples/hello-app:1.0 
    kubectl create deployment products-db -n products-prod --image=gcr.io/google-samples/hello-app:1.0

    #Create services for our deployments    
    kubectl apply -f ./services/products-ui-service.yaml
    kubectl apply -f ./services/products-business-service.yaml
    kubectl apply -f ./services/products-db-service.yaml
    #kubectl expose deployment products-ui -n products-prod --port=8080 --target-port=8080 --type=NodePort
    # kubectl expose deployment products-business -n products-prod --port=8080 --target-port=8080 --type=NodePort 
    # kubectl expose deployment products-db -n products-prod --port=8080 --target-port=8080 --type=NodePort 

    #Deploy PODs to products-stage name space
    kubectl create deployment products-ui --image=gcr.io/google-samples/hello-app:1.0 -n products-stage
    kubectl create deployment products-business --image=gcr.io/google-samples/hello-app:1.0 -n products-stage

    #Get the POD names for the UI, Business, and Databse tiers (products-prod name space)
    kubectl get pods -n products-prod
    UI_POD_NAME=$(kubectl get pods -no-headers -n products-prod | awk '{ print $1}' | grep products-ui)
    BUS_POD_NAME=$(kubectl get pods -no-headers -n products-prod | awk '{ print $1}' | grep products-business)
    DB_POD_NAME=$(kubectl get pods -no-headers -n products-prod | awk '{ print $1}' | grep products-db)
    
    #Get the POD names for the UI, and Business tiers (products-stage name space)
    BUS_POD_NAME_STAGE=$(kubectl get pods -n products-stage | awk '  NR>1 { print $1}' | grep products-business)
    UI_POD_NAME_STAGE=$(kubectl get pods -n products-stage | awk '  NR>1 { print $1}' | grep products-ui)

    #Get the Cluster IPs
    kubectl get services -o wide -n products-prod 
    #Get "products-ui" ClusterIP
    ProductsUIClusterIP=$(kubectl get service products-ui -n products-prod -o jsonpath='{ .spec.clusterIP }')
    #Get "products-business" ClusterIP
    ProductsBusinessClusterIP=$(kubectl get service products-business -n products-prod -o jsonpath='{ .spec.clusterIP }')
    #Get "products-db" ClusterIP
    ProductsDBClusterIP=$(kubectl get service products-db -n products-prod -o jsonpath='{ .spec.clusterIP }')  

    sleep 8s 
    kubectl get pods -n products-prod -o wide

    #Get IP addresses of PODs
    UI_POD_IP=$(kubectl get pods -no-headers -n products-prod -o wide | grep products-ui | awk '{print $6}')
    BUS_POD_IP=$(kubectl get pods -no-headers -n products-prod -o wide | grep products-business | awk '{print $6}')
    DB_POD_IP=$(kubectl get pods -no-headers -n products-prod -o wide | grep products-db | awk '{print $6}')
  
    echo "UI_POD_IP"=$UI_POD_IP
    echo "BUS_POD_IP"=$BUS_POD_IP
    echo "DB_POD_IP"=$DB_POD_IP
}

#***********************************************************************************************************************

function setup_env_svc(){

    cleanup

    #Create prod and stage name spaces
    kubectl create namespace products-prod 
    kubectl create namespace products-stage 

    #Create a new service account for prod "hello-world-bus" PODs. 
    kubectl create serviceaccount svcpoducts-bus-prod -n products-prod
    #Create a role the service account
    kubectl create role svcpoducts-prod-bus-role --verb=get,list --resource=pods -n products-prod
    #Bind the service account to role
    kubectl create rolebinding svcpoducts-prod-rolebinding --role=svcpoducts-prod-bus-role --serviceaccount=products-prod:svcpoducts-bus-prod 
    
    #Label the service account
    kubectl label  serviceaccount svcpoducts-bus-prod  -n products-prod env=prod

    #Create a new service account for stage "hello-world-bus" PODs. 
    kubectl create serviceaccount svcpoducts-bus-pilot -n products-stage
    #Create a role the service account
    kubectl create role svcpoducts-pilot-bus-role --verb=get,list --resource=pods -n products-stage
    #Bind the service account to role
    kubectl create rolebinding svcpoducts-pilot-rolebinding --role=svcpoducts-pilot-bus-role --serviceaccount=products-prod:svcpoducts-bus-pilot 
    
    #Label the service account
    kubectl label  serviceaccount svcpoducts-bus-pilot  -n products-stage env=pilot

    #Deploy prod PODs
    kubectl create deployment products-ui -n products-prod --image=gcr.io/google-samples/hello-app:1.0 
    kubectl apply -f ./cal/deploy-hello-world-bus-prod.yaml -n products-prod  
    kubectl create deployment products-db -n products-prod --image=gcr.io/google-samples/hello-app:1.0

    #Deploy stage POD
    kubectl create deployment products-ui --image=gcr.io/google-samples/hello-app:1.0 -n products-stage
    kubectl apply -f ./cal/deploy-hello-world-bus-stage.yml -n products-stage  

    kubectl expose deployment products-ui -n products-prod --port=8080 --target-port=8080 --type=NodePort 
    kubectl expose deployment products-bus -n products-prod --port=8080 --target-port=8080 --type=NodePort 
    kubectl expose deployment products-db -n products-prod --port=8080 --target-port=8080 --type=NodePort 
   

    UI_POD_NAME=$(kubectl get pods -no-headers -n products-prod  | awk '{print $1}'  | grep products-ui)
    BUS_POD_NAME=$(kubectl get pods -no-headers -n products-prod | awk '{ print $1}' | grep products-bus)
    DB_POD_NAME=$(kubectl get pods -no-headers -n products-prod  | awk '{ print $1}' | grep products-db)

    POD_BUSINESS_STAGE_NS=$(kubectl get pods -no-headers -n products-stage | awk '{ print $1}' | grep products-bus)
    POD_UI_STAGE_NS=$(kubectl get pods -no-headers -n products-stage       | awk '{ print $1}' | grep products-ui)

    #Get "products-ui" ClusterIP
    ProductsUIClusterIP=$(kubectl get service products-ui -n products-prod -o jsonpath='{ .spec.clusterIP }')

    #Get "products-business" ClusterIP
    ProductsBusinessClusterIP=$(kubectl get service products-bus -n products-prod -o jsonpath='{ .spec.clusterIP }')

    #Get "products-db" ClusterIP
    ProductsDBClusterIP=$(kubectl get service products-db -n products-prod -o jsonpath='{ .spec.clusterIP }')

}

#**********************************************************************************************************************

function cleanup(){       

    kubectl delete namespace products-stage;
    kubectl delete namespace products-prod
}


#*************************************Calico NetworkPolicy: Deny Sample*****************************************************************
setup_env

#Verify no Calico policies have been setup
calicoctl get networkpolicy -n products-prod
#Also
kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2 http://$ProductsBusinessClusterIP:8080 -O -  
kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2 http://$ProductsDBClusterIP:8080 -O - 

#Deny ui access to db
    calicoctl apply -f cal-deny-ingress-from-ui.yaml
    #Verify the policy was created
    calicoctl get networkpolicy -n products-prod
    #Test again
    kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2 http://$ProductsBusinessClusterIP:8080 -O -  
    kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2 http://$ProductsDBClusterIP:8080 -O - 

#Investigate Calico policy log
    #First check on which node the DB POD is hosted
    kubectl get pods -n products-prod -o wide
     #ssh into the node that hosts the "db" POD and run:
        grep 'calico-packet' /var/log/syslog
        #Show veth pairs
        ip link  show type veth

cleanup

#*************************************Calico NetWorkPolicy: Advanced*****************************************************************

#Investigate service accounts in teh defaultnme space
kubectl get serviceaccount

#Setup environment
setup_env_svc
#Investigate serviec accounts in stage and prod
kubectl get serviceaccount -n products-prod
kubectl get serviceaccount -n products-stage

kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2 http://$ProductsDBClusterIP:8080 -O -  
kubectl exec -it $BUS_POD_NAME -n products-prod -- wget -q --timeout=2 http://$ProductsDBClusterIP:8080 -O -
kubectl exec -it $POD_BUSINESS_STAGE_NS -n products-stage -- wget -q --timeout=2 http://$ProductsDBClusterIP:8080 -O -


#Apply the policy
    calicoctl apply -f cal-allow-ingress-from-svc.yaml
    #Test again
    kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2 http://$ProductsDBClusterIP:8080 -O -  
    kubectl exec -it $BUS_POD_NAME -n products-prod -- wget -q --timeout=2 http://$ProductsDBClusterIP:8080 -O -
    kubectl exec -it $POD_BUSINESS_STAGE_NS -n products-stage -- wget -q --timeout=2 http://$ProductsDBClusterIP:8080 -O -


#**********************************************************************************************************************


#*************************************Calico: Apply End Point policies and allow ingress only to a NodePort***********************************************************
setup_env

#Get a list of all of the nodes in the cluster:
calicoctl get nodes -o wide

calicoctl get hostendpoints

#Try accessing an unsecured phyton service from outside the master node
curl --max-time 1.5 http://10.0.0.157:8888

#Enable host end point specific to each ethernet interface  
#When the HostEndpoint is created, traffic to or from the interface is dropped unless policy is in place.   
    calicoctl apply -f kube-master-eth0.yaml
    calicoctl apply -f kube-node1-eth0.yml
    calicoctl apply -f kube-node2-eth0.yml
    #Check again
    calicoctl get hostendpoints
    calicoctl get hostendpoint kube-master-eth0 -o yaml

    #Above policy will block access to the phyton service (from outside the server.
    #Run from both inside and outside cluster)
    curl --max-time 1.5 http://localhost:8888 #This works because it is called from inside the server
    curl --max-time 1.5 http://10.0.0.157:8888

    #Above policy does not block NodePort access from inside/ouside the cluster
    #Run this from outside teh cluster
    #***ODD: Accesible from "ubuntuvm" but not cluster nodes!
    curl --max-time 1.5 http://10.0.0.157:30007

    #Above policy also blocks sh into PODs
    kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2  http://$BUS_POD_IP:8080 -O -

    #However, access to API server from outside cluster is still allowed
    #Run this from a machine outside the cluster due to "failsafe" rules
    curl -k --max-time 1.5 https://10.0.0.157:6443

#Alllow only in-cluster igress access 
    calicoctl apply -f allow-cluster-internal-ingress-only.yaml
        
    #Above will block Nodeport from outside the cluster
    #Run it from outside the cluster
    curl --max-time 1.5 http://10.0.0.157:30007

#Allow local hosts egress traffic 
calicoctl apply -f allow-outbound-external.yaml
    #Above policy restores sh into PODs
    kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2  http://$ProductsBusinessClusterIP:8080 -O - 
    kubectl exec -it $UI_POD_NAME -n products-prod -- wget -q --timeout=2  http://$BUS_POD_IP:8080 -O -

    #Above policy also allows access to phyton service from within the cluster.
    #Access is still denied from outside the cluster
    curl --max-time 1.5 http://10.0.0.157:8888    

#Allow NodePort #30007 ingress access from outside cluster    
calicoctl apply -f allow-nodeport-30007.yaml   
#curl -k --max-time 1.5 https://10.0.0.157:6443
#Try again this from a machine outside the cluster
    curl --max-time 1.5 http://10.0.0.157:30007

delete_nodeport_demo_policies
cleanup

#************************************************************************************************************************
function delete_nodeport_demo_policies() {
    
    calicoctl delete gnp allow-outbound-external
    calicoctl delete gnp allow-cluster-internal-ingress-only.yaml
    calicoctl delete HostEndpoint kube-master-eth0
    calicoctl delete HostEndpoint kube-node1-eth0
    calicoctl delete HostEndpoint kube-node2-eth0
    calicoctl delete gnp allow-cluster-internal-ingress-only
    calicoctl delete gnp allow-nodeport-30007
  
}
#************************************************************************************************************************

