#!/bin/bash
source `dirname $0`/config.sh

execute() {
  $@ || exit
}


echo "set default devhub user"
execute sf config set defaultdevhubusername=$DEV_HUB_ALIAS

echo "Deleting old scratch org"
sf org delete scratch --no-prompt --target-org $SCRATCH_ORG_ALIAS

echo "Creating scratch org"
execute sf org create scratch --alias $SCRATCH_ORG_ALIAS --set-default --definition-file ./config/scratch-org-def.json --duration-days 30

echo "Pushing changes to scratch org"
execute sf project deploy start

echo "Assigning permissions"
execute sf force user permset assign --perm-set-name Admin

echo "Make sure Org user is english"
sf data update record --sobject User --where "Name='User User'" --values "Languagelocalekey=en_US"

echo "Create sample data"
execute sfdx force:apex:execute -f scripts/createSampleData.apex

echo "Running Apex Tests"
execute sf apex run test --test-level RunLocalTests --wait 30 --code-coverage --result-format human

echo "Running Salesforce Code Analyser"
sf scanner run --format=table --target="./" --category="Security"
sf scanner run dfa --format=table --target="./" --projectdir="./" --category="Security"
sf scanner run --engine="pmd-appexchange" --format=table --target="./"
