resource "azurerm_policy_definition" "allowed_location_check" {
  name         = "only-deploy-in-westeurope"
  display_name = "only-deploy-in-westeurope"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = <<POLICY_RULE
    {
    "if": {
      "not": {
        "field": "location",
        "equals": "westeurope"
      }
    },
    "then": {
      "effect": "audit"
    }
  }
POLICY_RULE
}

resource "azurerm_resource_group_policy_assignment" "location_policy_to_rg" {
  name                 = "allowed_location-policy-assignment"
  resource_id          = var.RG.id
  policy_definition_id = azurerm_policy_definition.allowed_location_check.id
}
