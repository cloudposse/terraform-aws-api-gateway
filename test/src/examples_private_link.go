package test

import (
	"crypto/tls"
	"fmt"
	"math/rand"
	"strconv"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesPrivateLink(t *testing.T) {
	t.Parallel()

	rand.Seed(time.Now().UnixNano())
	randID := strconv.Itoa(rand.Intn(100000))
	attributes := []string{randID}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../../examples/private-link",
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

	// Run `terraform output` to get the value of an output variable
	today := time.Now().UTC().Truncate(24 * time.Hour).String()
	created_date, _ := time.Parse(time.RFC3339, terraform.Output(t, terraformOptions, "created_date"))
	created_date = created_date.Truncate(24 * time.Hour)

	assert.Equal(t, today, created_date.String())

	// Run `terraform output` to get the value of an output variable
	gatewayURL := terraform.Output(t, terraformOptions, "invoke_url")
	checkURL := fmt.Sprintf("%s/%s", gatewayURL, "path1")

	// Make a GET request to the URL and inspect the response
	tlsConfig := tls.Config{}
	maxRetries := 5
	timeBetweenRetries := 5 * time.Second

	// Verify that we get back a 200 OK
	http_helper.HttpGetWithRetryWithCustomValidation(t, checkURL, &tlsConfig, maxRetries, timeBetweenRetries, func(statusCode int, body string) bool {
		return statusCode == 200
	})
}

// Test the Terraform module in examples/complete doesn't attempt to create resources with enabled=false.
func TestExamplesPrivateLinkDisabled(t *testing.T) {
	testNoChanges(t, "../../examples/private-link")
}
