import logging
import pytest
import requests

from meal_max.utils.logger import configure_logger
from meal_max.utils.random_utils import get_random


logger = logging.getLogger(__name__)
configure_logger(logger)

def test_get_random_success(mocker):
    """Test the successful fetching of a random number."""
    mock_response = mocker.Mock()
    mock_response.text = "0.42"
    mock_response.raise_for_status = mocker.Mock()

    # Mocking requests.get to return the mock_response
    mocker.patch('meal_max.utils.random_utils.requests.get', return_value=mock_response)

    result = get_random()
    assert result == 0.42
    mock_response.raise_for_status.assert_called_once()

def test_get_random_invalid_response(mocker):
    """Test handling of invalid response from random.org."""
    mock_response = mocker.Mock()
    mock_response.text = "invalid"
    mock_response.raise_for_status = mocker.Mock()

    # Mocking requests.get to return the mock_response
    mocker.patch('meal_max.utils.random_utils.requests.get', return_value=mock_response)

    with pytest.raises(ValueError, match="Invalid response from random.org: invalid"):
        get_random()

def test_get_random_timeout(mocker):
    """Test handling of a timeout error."""
    # Mocking requests.get to raise a Timeout exception
    mocker.patch('meal_max.utils.random_utils.requests.get', side_effect=requests.exceptions.Timeout)

    with pytest.raises(RuntimeError, match="Request to random.org timed out."):
        get_random()

def test_get_random_request_exception(mocker):
    """Test handling of a generic request exception."""
    mock_response = mocker.Mock()
    mock_response.raise_for_status.side_effect = requests.exceptions.RequestException("Connection Error")

    # Mocking requests.get to return the mock_response
    mocker.patch('meal_max.utils.random_utils.requests.get', return_value=mock_response)

    with pytest.raises(RuntimeError, match="Request to random.org failed: Connection Error"):
        get_random()
