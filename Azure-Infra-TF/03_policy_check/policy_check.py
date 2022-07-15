import logging
from azure.mgmt.policyinsights._policy_insights_client import PolicyInsightsClient
from azure.mgmt.policyinsights.models import QueryOptions
from azure.identity import DefaultAzureCredential
from azure.mgmt.subscription import SubscriptionClient
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    credential = DefaultAzureCredential(exclude_visual_studio_code_credential=True)
    subscription_client = SubscriptionClient(credential)
    sub_list = list(subscription_client.subscriptions.list())

    output = []

    for id in sub_list:
        subId = f'{id.subscription_id}'
        policyClient = PolicyInsightsClient(credential, subId, base_url=None)

        # Set the policy query options
        queryOptions = QueryOptions(filter="IsCompliant eq false and PolicyAssignmentId eq '/subscriptions/" \
            + subId + "/resourcegroups/test_managed_via_tf/providers/microsoft.authorization/policyassignments/allowed_location-policy-assignment'", \
            apply="groupby((ResourceId))")

        # Fetch 'latest' results for the subscription
        results = policyClient.policy_states.list_query_results_for_subscription(policy_states_resource="latest", \
            subscription_id=subId, query_options=queryOptions)
        
        # save results into a list
        for index, resource in enumerate(results):
            output.append("Noncompliant resource [" + str(index) + "]=")
            output.append(str(resource.resource_id))

    return func.HttpResponse(status_code=200,headers={'content-type':'text/html'}, 
        body=str(output))
