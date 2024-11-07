#!/bin/bash

# Define the base URL for the Flask API
BASE_URL="http://localhost:5000/api"

# Flag to control whether to echo JSON output
ECHO_JSON=false

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    --echo-json) ECHO_JSON=true ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

###############################################
#
# Health checks
#
###############################################

# Function to check the health of the service
check_health() {
  echo "Checking health status..."
  curl -s -X GET "$BASE_URL/health" | grep -q '"status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Service is healthy."
  else
    echo "Health check failed."
    exit 1
  fi
}

# Function to check the database connection
check_db() {
  echo "Checking database connection..."
  curl -s -X GET "$BASE_URL/db-check" | grep -q '"database_status": "healthy"'
  if [ $? -eq 0 ]; then
    echo "Database connection is healthy."
  else
    echo "Database check failed."
    exit 1
  fi
}

###############################################
#
# Meals
#
###############################################

create_meal() {
  meal=$1
  cuisine=$2
  price=$3
  difficulty=$4

  echo "Adding meal to db: $meal - $cuisine, $price, $difficulty"
  response=$(curl -s -X POST "$BASE_URL/create-meal" \
    -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\", \"cuisine\":\"$cuisine\", \"price\":$price, \"difficulty\":\"$difficulty\"}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal added successfully."
  else
    echo "Failed to add meal."
    exit 1
  fi
}

clear_meals() {
  echo "Clearing meals..."
  response=$(curl -s -X DELETE "$BASE_URL/clear-meals")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meals cleared successfully."
  else
    echo "Failed to clear meals."
    exit 1
  fi
}

delete_meal_by_id() {
  meal_id=$1

  echo "Deleting meal by ID ($meal_id)..."
  response=$(curl -s -X DELETE "$BASE_URL/delete-meal/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal deleted successfully by ID ($meal_id)."
  else
    echo "Failed to delete meal by ID ($meal_id)."
    exit 1
  fi
}

get_meal_by_id() {
  meal_id=$1

  echo "Getting meal by ID ($meal_id)..."
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-id/$meal_id")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by ID ($meal_id)."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (ID $meal_id):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by ID ($meal_id)."
    exit 1
  fi
}

get_meal_by_name() {
  meal_name=$1
  meal_name_encoded=$(echo -n "$meal_name" | jq -s -R -r @uri)

  echo "Getting meal by name: $meal_name"
  response=$(curl -s -X GET "$BASE_URL/get-meal-by-name/$meal_name_encoded")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meal retrieved successfully by name."
    if [ "$ECHO_JSON" = true ]; then
      echo "Meal JSON (by name):"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get meal by name."
    echo $response
    exit 1
  fi
}

############################################################
#
# Battle
#
############################################################

battle() {
  echo "Starting battle..."
  response=$(curl -s -X GET "$BASE_URL/battle")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Meals successfully battled, $(echo -n "$response" | jq -r .winner) is the winner"
  else
    echo "Failed to start battle: $(echo -n "$response" | jq -r .error)"
    exit 1
  fi
}

clear_combatants() {
  echo "Clearing combatants..."
  response=$(curl -s -X POST "$BASE_URL/clear-combatants")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatants cleared successfully."
  else
    echo "Failed to clear combatants."
    exit 1
  fi
}

get_combatants() {
  echo "Getting combatants..."
  response=$(curl -s -X GET "$BASE_URL/get-combatants")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Combatants retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Combatants JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get combatants."
    exit 1
  fi
}

prep_combatant() {
  meal=$1
  echo "Prepping combatant: $meal..."
  response=$(curl -s -X POST "$BASE_URL/prep-combatant" \
    -H "Content-Type: application/json" \
    -d "{\"meal\":\"$meal\"}")

  if echo "$response" | grep -q '"status": "success"'; then
    echo "$meal successfully prepped."
  else
    echo "Failed to prep meal: $(echo -n "$response" | jq -r .error)"
    exit 1
  fi
}

############################################################
#
# Leaderboard
#
############################################################

get_leaderboard() {
  echo "Getting leaderboard..."
  response=$(curl -s -X GET "$BASE_URL/leaderboard")
  if echo "$response" | grep -q '"status": "success"'; then
    echo "Leaderboard retrieved successfully."
    if [ "$ECHO_JSON" = true ]; then
      echo "Leaderboard JSON:"
      echo "$response" | jq .
    fi
  else
    echo "Failed to get leaderboard."
    exit 1
  fi
}

# Health checks
check_health
check_db

#Meals
clear_meals

create_meal "Bangers and Mash" "British" 3.0 "LOW"
create_meal "Pad Thai" "Thai" 4.5 "MED"
create_meal "Beef Bourguignon" "French" 6.0 "HIGH"
create_meal "Chicken Tikka Masala" "Indian" 5.0 "MED"
create_meal "Tacos" "Mexican" 3.5 "LOW"

delete_meal_by_id 1

get_meal_by_id 2

get_meal_by_name "Chicken Tikka Masala"

echo

#Battle
clear_combatants

prep_combatant "Pad Thai"
prep_combatant "Tacos"

get_combatants

battle

prep_combatant "Beef Bourguignon"

battle

prep_combatant "Chicken Tikka Masala"

battle

get_leaderboard

clear_combatants

clear_meals

echo "All tests passed successfully!"