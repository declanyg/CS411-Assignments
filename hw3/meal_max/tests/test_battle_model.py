import logging
import pytest
import re
from contextlib import contextmanager

from meal_max.models.kitchen_model import Meal
from meal_max.models.battle_model import BattleModel

from meal_max.utils.logger import configure_logger

logger = logging.getLogger(__name__)
configure_logger(logger)

#Fixtures
@pytest.fixture()
def battle_model():
    """Fixture to provide a new instance of BattleModel for each test."""
    return BattleModel()

"""Fixtures providing sample meals for the tests."""
@pytest.fixture
def sample_meal1():
    return Meal(1, "Meal A", "Cuisine A", 1.0, "LOW") #6.0

@pytest.fixture
def sample_meal2():
    return Meal(2, "Meal B", "Cuisine B", 2.0, "MED") #16.0


#Battle
def test_battle_not_enough_combatants(battle_model):
    model = battle_model
    with pytest.raises(ValueError, match="Two combatants must be prepped for a battle."):
        model.battle()

def test_battle_success(mocker, battle_model, sample_meal1, sample_meal2):

    #Meal 1 win
    mocker.patch("meal_max.models.battle_model.get_random", return_value=0.09)

    mocker.patch("meal_max.models.battle_model.update_meal_stats")

    battle_model.combatants = [sample_meal1, sample_meal2]
    
    assert battle_model.battle() == sample_meal1.meal
    assert len(battle_model.combatants) == 1

    #Meal 2 win

    battle_model.combatants = [sample_meal1, sample_meal2]

    mocker.patch("meal_max.models.battle_model.get_random", return_value=0.11)

    assert battle_model.battle() == sample_meal2.meal
    assert len(battle_model.combatants) == 1

#Clear combatants
def test_clear_combatants(battle_model, sample_meal1, sample_meal2):
    battle_model.combatants.extend([sample_meal1, sample_meal2])
    assert len(battle_model.combatants) == 2
    battle_model.clear_combatants()
    assert len(battle_model.combatants) == 0

#Get battle score
def test_get_battle_score(battle_model, sample_meal1):
    #(1.0 * 9) - 3
    assert battle_model.get_battle_score(sample_meal1) == 6.0

#Get Combatants
def test_get_combatants(battle_model, sample_meal1, sample_meal2):
    """Test getting the combatants of the battle."""
    battle_model.combatants.extend([sample_meal1, sample_meal2])
    assert battle_model.get_combatants() == [sample_meal1, sample_meal2]

#Prep Combatants
def test_prep_combatant(battle_model, sample_meal1):
    battle_model.prep_combatant(sample_meal1)
    assert len(battle_model.combatants) == 1
    assert battle_model.combatants[0].meal == 'Meal A'

def test_prep_combatant_full(battle_model, sample_meal1, sample_meal2):
    model = battle_model
    battle_model.combatants.extend([sample_meal1, sample_meal2])
    with pytest.raises(ValueError, match="Combatant list is full, cannot add more combatants."):
        model.prep_combatant(Meal(3, "Meal C", "Cuisine C", 3.0, "HIGH"))