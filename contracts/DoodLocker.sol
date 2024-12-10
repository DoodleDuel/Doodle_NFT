// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DoodleLocker is AxelarExecutable, IERC721Receiver, Ownable {
    // Mapping tokenId => (tokenAddress => amount for ERC20 or quantity for NFTs)
    mapping(uint256 => mapping(address => uint256)) public tokenBalances;

    // Mapping tokenId => (ERC721 contract address => list of token IDs)
    mapping(uint256 => mapping(address => uint256[])) public nftBalances;

    // Tracks ownership proofs for a tokenId
    mapping(uint256 => address) public ownershipProved;

    // Authorized source chain and address
    string public authorizedSourceChain;
    address public authorizedSourceAddress;

    event TokensLocked(
        uint256 indexed tokenId,
        address indexed depositor,
        address token,
        uint256 amount
    );
    event NFTLocked(
        uint256 indexed tokenId,
        address indexed depositor,
        address nftContract,
        uint256 nftId
    );
    event TokensWithdrawn(
        uint256 indexed tokenId,
        address indexed owner,
        address token,
        uint256 amount
    );
    event NFTWithdrawn(
        uint256 indexed tokenId,
        address indexed owner,
        address nftContract,
        uint256 nftId
    );
    event OwnershipProved(address indexed user, uint256 tokenId);

    constructor(
        address gateway,
        string memory sourceChain,
        address _sourceAddress
    ) AxelarExecutable(gateway) Ownable(msg.sender) {
        authorizedSourceChain = sourceChain;
        authorizedSourceAddress = _sourceAddress;
    }

    /**
     * @notice Deposit ETH into the locker assigned to a specific tokenId
     * @param tokenId The NFT tokenId this deposit is associated with
     */
    function depositETH(uint256 tokenId) external payable {
        require(msg.value > 0, "Must deposit some ETH");
        tokenBalances[tokenId][address(0)] += msg.value;
        emit TokensLocked(tokenId, msg.sender, address(0), msg.value);
    }

    /**
     * @notice Deposit ERC20 tokens into the locker assigned to a specific tokenId
     * @param tokenId The NFT tokenId this deposit is associated with
     * @param token The ERC20 token address to deposit
     * @param amount The amount of tokens to deposit
     */
    function depositERC20(
        uint256 tokenId,
        address token,
        uint256 amount
    ) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        bool success = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "Token transfer failed");

        tokenBalances[tokenId][token] += amount;
        emit TokensLocked(tokenId, msg.sender, token, amount);
    }

    /**
     * @notice Deposit ERC721 NFTs into the locker assigned to a specific tokenId
     * @param tokenId The NFT tokenId this deposit is associated with
     * @param nftContract The ERC721 contract address
     * @param nftId The ID of the NFT to deposit
     */
    function depositERC721(
        uint256 tokenId,
        address nftContract,
        uint256 nftId
    ) external {
        require(nftContract != address(0), "Invalid contract address");

        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), nftId);
        nftBalances[tokenId][nftContract].push(nftId);

        emit NFTLocked(tokenId, msg.sender, nftContract, nftId);
    }

    /**
     * @notice Execute function to handle incoming Axelar messages proving NFT ownership
     * @param commandId The Axelar command ID for this message
     * @param _sourceChain The source chain where the message originated
     * @param _sourceAddress The address of the Doods contract on the source chain
     * @param _payload Encoded payload containing user address and tokenId
     */
    function _execute(
        bytes32 commandId,
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override {
        require(
            keccak256(abi.encodePacked(_sourceChain)) ==
                keccak256(abi.encodePacked(authorizedSourceChain)),
            "Unauthorized source chain"
        );
        require(
            keccak256(abi.encodePacked(_sourceAddress)) ==
                keccak256(abi.encodePacked(authorizedSourceAddress)),
            "Unauthorized source address"
        );

        (address user, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );
        ownershipProved[tokenId] = user;

        emit OwnershipProved(user, tokenId);
    }

    function proveOwnership(uint256 tokenId, address user) external {
        require(
            msg.sender == authorizedSourceAddress,
            "Unauthorized source address"
        );

        ownershipProved[tokenId] = user;
        emit OwnershipProved(user, tokenId);
    }

    /**
     * @notice Withdraw ETH or ERC20 tokens for a given tokenId
     * @param tokenId The tokenId associated with the locker
     * @param token The token address (use address(0) for ETH)
     * @param amount The amount to withdraw
     */
    function withdraw(uint256 tokenId, address token, uint256 amount) external {
        require(
            ownershipProved[tokenId] == msg.sender,
            "Not authorized to withdraw"
        );

        uint256 balance = tokenBalances[tokenId][token];
        require(balance >= amount, "Insufficient balance");

        tokenBalances[tokenId][token] -= amount;

        if (token == address(0)) {
            // Withdraw ETH
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            // Withdraw ERC20 tokens
            bool success = IERC20(token).transfer(msg.sender, amount);
            require(success, "Token transfer failed");
        }

        emit TokensWithdrawn(tokenId, msg.sender, token, amount);
    }

    /**
     * @notice Withdraw an ERC721 NFT for a given tokenId
     * @param tokenId The tokenId associated with the locker
     * @param nftContract The NFT contract address
     * @param nftId The NFT ID to withdraw
     */
    function withdrawNFT(
        uint256 tokenId,
        address nftContract,
        uint256 nftId
    ) external {
        require(
            ownershipProved[tokenId] == msg.sender,
            "Not authorized to withdraw"
        );

        uint256[] storage nftIds = nftBalances[tokenId][nftContract];
        bool found = false;

        // Remove the NFT ID from the list
        for (uint256 i = 0; i < nftIds.length; i++) {
            if (nftIds[i] == nftId) {
                nftIds[i] = nftIds[nftIds.length - 1];
                nftIds.pop();
                found = true;
                break;
            }
        }
        require(found, "NFT not found");

        IERC721(nftContract).safeTransferFrom(address(this), msg.sender, nftId);
        emit NFTWithdrawn(tokenId, msg.sender, nftContract, nftId);
    }

    /**
     * @notice Update the authorized source chain and address
     * @param _sourceChain The new source chain
     * @param _sourceAddress The new source address
     */
    function updateAuthorizedSource(
        string calldata _sourceChain,
        address _sourceAddress
    ) external onlyOwner {
        authorizedSourceChain = _sourceChain;
        authorizedSourceAddress = _sourceAddress;
    }

    // Fallback to receive ETH
    receive() external payable {}

    /**
     * @dev Implementation of IERC721Receiver interface
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
