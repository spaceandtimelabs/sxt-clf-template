// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Functions, FunctionsClient} from "@spaceandtime/contracts/functions/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/**
 * @title Functions Consumer contract for String type Response
 * @notice This contract is a demonstration of using Functions(Beta).
 * @notice NOT FOR PRODUCTION USE
 */
contract FunctionsConsumer is FunctionsClient, ConfirmedOwner {
	using Functions for Functions.Request;

	/**
	* Steps to use this boilerplate contract:
	* 1. Get access to chainlink functions for your EVM wallet address on https://chainlinkcommunity.typeform.com/requestaccess
	* 2. Edit this boilerplate contract in an editor of your choice
	* 3. Ensure you have sufficient ETH and LINK balance in your wallet
	* 4. Deploy the smart contract with appropriate constructor parameters on either Mumbai/Sepolia testnets
	* 5. For managing Chainlink Functions Subscription, select 'Chainlink Subscription' on dApp, here you can do following:
	*   - Create new subscription with the wallet that you got approved in step-1
		- Fund the Subscription with LINK tokens
		- Add your deployed contract as consumer in the subscription
	* 6. For running a request execute the executeRequest() with appropriate parameters
	* 7. Read the response in bytes using the latestResponse() function
	* 8. Read the response after decoding to string using the getStringResponse() function
	*/

	/// @dev Zero Address
	address constant ZERO_ADDRESS = address(0);

	/// @dev Latest request ID created using this contract
	bytes32 public latestRequestId;

	/// @dev Response for the latest request created using this contract
	bytes public latestResponse;

	/// @dev Error for the latest request created using this contract. Empty if response received successfully
	bytes public latestError;

	event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

	/**
	 * @notice Executes once when a contract is created to initialize state variables
	 * @param oracle - The FunctionsOracle contract
	 *
	 * Mumbai network details:
	 * oracle: 0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4
	 *
	 * Sepolia network details:
	 * oracle: 0x649a2C205BE7A3d5e99206CEEFF30c794f0E31EC
	 *
	 */
	// https://github.com/protofire/solhint/issues/242
	// solhint-disable-next-line no-empty-blocks
	constructor(address oracle) FunctionsClient(oracle) ConfirmedOwner(msg.sender) {}

	/**
	 * @notice Send a simple request
	 *
	 * @param source JavaScript source code
	 * @param secrets Encrypted secrets payload
	 * @param args List of arguments accessible from within the source code
	 * @param subscriptionId Funtions billing subscription ID
	 * @param gasLimit Maximum amount of gas used to call the client contract's `handleOracleFulfillment` function
	 * @return Functions request ID
	 */
	function executeRequest(
		string calldata source,
		bytes calldata secrets,
		string[] calldata args,
		uint64 subscriptionId,
		uint32 gasLimit
	) public onlyOwner returns (bytes32) {
		Functions.Request memory req;
		req.initializeRequest(
			Functions.Location.Inline,
			Functions.CodeLanguage.JavaScript,
			source
		);
		if (secrets.length > 0) {
			req.addRemoteSecrets(secrets);
		}
		if (args.length > 0) req.addArgs(args);

		bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
		latestRequestId = assignedReqID;
		return assignedReqID;
	}

	/**
	 * @notice Callback that is invoked once the DON has resolved the request or hit an error
	 *
	 * @param requestId The request ID, returned by sendRequest()
	 * @param response Aggregated response from the user code
	 * @param err Aggregated error from the user code or from the execution pipeline
	 * Either response or error parameter will be set, but never both
	 */
	function fulfillRequest(
		bytes32 requestId,
		bytes memory response,
		bytes memory err
	) internal override {
		latestResponse = response;
		latestError = err;
		emit OCRResponse(requestId, response, err);
	}

	/**
	 * @notice Allows the Functions oracle address to be updated
	 * @param newOracleAddress New oracle address to be set in the consumer contract
	 */
	function updateOracleAddress(address newOracleAddress) public onlyOwner {
		require(
			newOracleAddress != ZERO_ADDRESS,
			"FunctionsConsumer: Cannot set to Zero Address"
		);
		setOracle(newOracleAddress);
	}

	/**
	 * @notice Provides decoded string value of latest response
	 * @return decodedStringResponse decoded string value of latest response
	 */
	function getStringResponse() public view returns (string memory decodedStringResponse)
	{
		return string(latestResponse);
	}

	function addSimulatedRequestId(address oracleAddress, bytes32 requestId) public onlyOwner {
		addExternalRequest(oracleAddress, requestId);
	}
}