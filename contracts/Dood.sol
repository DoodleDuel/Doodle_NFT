// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IDoodleLocker {
    function proveOwnership(uint256 tokenId, address owner) external;
}

contract Doods is ERC721, Ownable {
    IAxelarGateway public gateway;
    IAxelarGasService public gasService;

    // Base URL for token metadata
    string public baseTokenURI; // we will change this to IPFS URL
    string public extension = ""; // later .json


    // Token ID counter for auto-incrementing mints
    uint256 public currentTokenId = 0;

    // Struct to store cross-chain locker information
    struct Locker {
        string chain;
        string lockerAddress;
    }

    // Mapping from tokenId to the owner's address
    mapping(uint256 => address) public owners;

    // Mapping from tokenId to its associated lockers
    mapping(uint256 => Locker[]) public tokenLockers;

    // Mapping to check if a locker is on the same chain
    mapping(uint256 => bool) public isLockerOnSameChain;

    // Address of the Locker contract on the same chain
    address public sameChainLockerAddress;

    constructor(
        address _gateway,
        address _gasService,
        string memory _baseTokenURI
    ) ERC721("Doods", "DOODS") Ownable(msg.sender) {
        gateway = IAxelarGateway(_gateway);
        gasService = IAxelarGasService(_gasService);
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @notice Mint a new Doods NFT with an auto-incrementing tokenId
     * @dev Only the contract owner can mint
     */
    function mint() public onlyOwner {
        currentTokenId++;
        uint256 tokenId = currentTokenId;
        _mint(msg.sender, tokenId);
        owners[tokenId] = msg.sender;
    }

    /**
     * @notice Add a cross-chain locker for a given tokenId
     * @param tokenId The ID of the token
     * @param chain The destination chain name
     * @param lockerAddress The address of the locker on the destination chain
     */
    function addLocker(
        uint256 tokenId,
        string memory chain,
        string memory lockerAddress
    ) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the token owner can add lockers"
        );
        tokenLockers[tokenId].push(Locker(chain, lockerAddress));
    }

    /**
     * @notice Prove ownership to a cross-chain locker
     * @dev You must send enough native currency (e.g., ETH) with this call to pay for the remote gas.
     * @param tokenId The ID of the token
     * @param chain The destination chain name
     * @param lockerAddress The address of the locker contract on the destination chain
     */
    function proveOwnership(
        uint256 tokenId,
        string memory chain,
        string memory lockerAddress
    ) public payable {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the token owner can prove ownership"
        );

        bytes memory payload = abi.encode(msg.sender, tokenId);

        // Pay for gas on the Axelar network upfront
        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            chain,
            lockerAddress,
            payload,
            msg.sender // refund address if applicable
        );

        // Send the payload to the destination chain via Axelar Gateway
        gateway.callContract(chain, lockerAddress, payload);
    }

    /**
     * @notice Set the locker as on the same chain
     * @param tokenId The ID of the token
     * @param _isOnSameChain Whether the locker is on the same chain
     */
    function setLockerOnSameChain(uint256 tokenId, bool _isOnSameChain) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the token owner can set this"
        );
        isLockerOnSameChain[tokenId] = _isOnSameChain;
    }

    /**
     * @notice Set the address of the locker on the same chain
     * @param _sameChainLockerAddress The address of the locker contract on the same chain
     */
    function setSameChainLockerAddress(
        address _sameChainLockerAddress
    ) public onlyOwner {
        sameChainLockerAddress = _sameChainLockerAddress;
    }

    /**
     * @notice Prove ownership to a locker on the same chain
     * @param tokenId The ID of the token
     */
    function proveOwnershipSameChain(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only the token owner can prove ownership"
        );
        require(
            isLockerOnSameChain[tokenId],
            "Locker is not on the same chain"
        );

        // Call the locker directly on the same chain
        IDoodleLocker(sameChainLockerAddress).proveOwnership(
            tokenId,
            msg.sender
        );
    }

    /**
     * @notice Get all lockers associated with a token
     * @param tokenId The ID of the token
     * @return An array of lockers associated with the token
     */
    function getLockers(uint256 tokenId) public view returns (Locker[] memory) {
        return tokenLockers[tokenId];
    }

    /**
     * @notice Update the base URL for token metadata
     * @param _baseTokenURI The new base URL
     */
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @notice Update the file extension for token metadata
     * @param _extension The new file extension
     */
    function setExtension(string memory _extension) public onlyOwner {
        extension = _extension;
    }

    /**
     * @notice Override tokenURI to generate metadata URLs dynamically
     * @param tokenId The ID of the token
     * @return The complete URL for the token metadata
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(tokenId),
                    extension
                )
            );
    }
}
