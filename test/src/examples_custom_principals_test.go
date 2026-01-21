package test

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"strconv"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test the custom principals parameter ensures correct IAM trust policy
func TestExamplesCustomPrincipals(t *testing.T) {
	t.Parallel()

	rand.Seed(time.Now().UnixNano())
	randID := strconv.Itoa(rand.Intn(100000))
	attributes := []string{randID}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/with-custom-principals",
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: []string{"fixtures.us-east-2.tfvars"},
		// We always include a random attribute so that parallel tests
		// and AWS resources do not interfere with each other
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    true,
		},
	})

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Get the CloudWatch role ARN from terraform output
	cloudwatchRoleArn := terraform.Output(t, terraformOptions, "cloudwatch_role_arn")
	require.NotEmpty(t, cloudwatchRoleArn, "CloudWatch role ARN should not be empty")

	// Extract region from terraform options
	region := "us-east-2"

	// Get the IAM role name from the ARN
	roleName := extractRoleNameFromArn(cloudwatchRoleArn)
	require.NotEmpty(t, roleName, "Role name should not be empty")

	// Get the IAM role trust policy
	role := aws.GetIamRole(t, region, roleName)
	require.NotNil(t, role, "IAM role should exist")

	// Parse the trust policy
	var trustPolicy map[string]interface{}
	err := json.Unmarshal([]byte(*role.AssumeRolePolicyDocument), &trustPolicy)
	require.NoError(t, err, "Should be able to parse trust policy JSON")

	// Verify the trust policy contains apigateway.amazonaws.com as principal
	statements := trustPolicy["Statement"].([]interface{})
	require.NotEmpty(t, statements, "Trust policy should have statements")

	foundCorrectPrincipal := false
	for _, stmt := range statements {
		statement := stmt.(map[string]interface{})
		if principal, ok := statement["Principal"].(map[string]interface{}); ok {
			if service, ok := principal["Service"]; ok {
				// Service can be a string or array
				switch v := service.(type) {
				case string:
					if v == "apigateway.amazonaws.com" {
						foundCorrectPrincipal = true
					}
				case []interface{}:
					for _, svc := range v {
						if svc == "apigateway.amazonaws.com" {
							foundCorrectPrincipal = true
						}
					}
				}
			}
		}
	}

	assert.True(t, foundCorrectPrincipal,
		"Trust policy should contain apigateway.amazonaws.com as principal service. "+
		"This validates the fix for issue #35.")

	// Verify API Gateway was created successfully
	apiId := terraform.Output(t, terraformOptions, "id")
	require.NotEmpty(t, apiId, "API Gateway ID should not be empty")

	// Verify we can get the invoke URL (proves API Gateway is functional)
	invokeUrl := terraform.Output(t, terraformOptions, "invoke_url")
	require.NotEmpty(t, invokeUrl, "Invoke URL should not be empty")

	fmt.Printf("✅ API Gateway created successfully with correct IAM principal\n")
	fmt.Printf("   API ID: %s\n", apiId)
	fmt.Printf("   IAM Role: %s\n", roleName)
	fmt.Printf("   Invoke URL: %s\n", invokeUrl)
}

// Helper function to extract role name from ARN
// Example ARN: arn:aws:iam::123456789012:role/role-name
func extractRoleNameFromArn(arn string) string {
	// Simple parsing - in production you'd want more robust parsing
	var roleName string
	fmt.Sscanf(arn, "arn:aws:iam::%*d:role/%s", &roleName)
	return roleName
}
