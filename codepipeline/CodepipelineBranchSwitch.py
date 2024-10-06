import boto3
import argparse
import sys

# Initialize the boto3 clients
codepipeline_client = boto3.client('codepipeline')

# Replace with your values
codepipeline_name = 'TransferFamilyPipeline'
webhook_name = 'TransferFamilyPipelineWebhook'
github_webhook_secret = 'e2b5f3a9f9be3b3c884266e39cf2c731cf3d1a7ee35e52708bb181398224c528'

def update_codepipeline_branch(pipeline_name, branch):
    """
    Update the branch name for the CodePipeline Source stage.
    """
    try:
        # Get the pipeline definition
        response = codepipeline_client.get_pipeline(name=pipeline_name)
        pipeline = response['pipeline']

        # Update the branch name in the source stage
        for stage in pipeline['stages']:
            if stage['name'] == 'Source':
                for action in stage['actions']:
                    if action['name'] == 'Source':
                        action['configuration']['BranchName'] = branch

        # Update the pipeline with the new branch
        codepipeline_client.update_pipeline(pipeline=pipeline)
        print(f"Updated branch to '{branch}' in CodePipeline '{pipeline_name}'.")
    except Exception as e:
        print(f"Error updating branch name in CodePipeline: {e}")

def update_codepipeline_webhook(webhook_name, branch):
    """
    Update the CodePipeline webhook filter to match the new branch.
    """
    try:
        # Get the current webhook details
        response = codepipeline_client.list_webhooks()
        webhooks = response.get('webhooks', [])

        # Find the webhook by name
        webhook = next((w for w in webhooks if w['definition']['name'] == webhook_name), None)

        if webhook:
            # Update the webhook filter for the new branch
            webhook['definition']['filters'][0]['matchEquals'] = f"refs/heads/{branch}"

            # Update the webhook configuration
            codepipeline_client.put_webhook(
                webhook={
                    'name': webhook_name,
                    'targetPipeline': webhook['definition']['targetPipeline'],
                    'targetAction': webhook['definition']['targetAction'],
                    'filters': webhook['definition']['filters'],
                    'authentication': webhook['definition']['authentication'],
                    'authenticationConfiguration': {
                        'SecretToken': github_webhook_secret
                    }
                }
            )
            print(f"Updated webhook '{webhook_name}' filter to match branch '{branch}'.")
        else:
            print(f"No webhook found with the name '{webhook_name}'.")
    except Exception as e:
        print(f"Error updating webhook filter: {e}")

def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Dynamically update CodePipeline and Webhook branch settings.")
    parser.add_argument('branch', type=str, help="Branch name to switch to (e.g., feature/new-branch).")

    # Parse the arguments
    args = parser.parse_args()

    # If the branch name starts with '-', print an error and exit
    if args.branch.startswith('-'):
        print("Error: Branch name cannot start with a dash. Please input a valid branch name.")
        sys.exit(1)

    # Execute updates with the provided branch name
    branch_name = args.branch
    update_codepipeline_branch(codepipeline_name, branch_name)
    update_codepipeline_webhook(webhook_name, branch_name)

if __name__ == "__main__":
    main()
