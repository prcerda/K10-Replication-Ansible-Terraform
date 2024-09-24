header_export="policy,string,app"

kubectl get policy -n kasten-io -o jsonpath='{range .items[*]}{.metadata.name}{","}{.spec.actions[?(@.action=="export")].exportParameters.receiveString}{","}{.spec.selector.matchExpressions[0].values[0]}{"\n"}{end}' > import_details.csv