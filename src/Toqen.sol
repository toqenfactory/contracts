// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 *   ooooooooooooo
 *   8'   888   `8
 *        888       .ooooo.   .ooooo oo  .ooooo.  ooo. .oo.
 *        888      d88' `88b d88' `888  d88' `88b `888P"Y88b
 *        888      888   888 888   888  888ooo888  888   888
 *        888      888   888 888   888  888    .o  888   888
 *       o888o     `Y8bod8P' `V8bod888  `Y8bod8P' o888o o888o
 *                                 888.
 *                                 8P'
 *                                 "
 */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title A token contract for ERC20 tokens with minting and withdrawal functionality
contract ERC20Toqen is ERC20, ERC20Permit, ReentrancyGuard {
    /// @notice The owner of the token contract
    address public immutable owner;
    /// @notice The maximum supply of tokens that can be minted
    uint256 public immutable maxSupply;
    /// @notice The price per token in Wei
    uint256 public immutable tokenPrice;

    /**
     * @notice Creates a new ERC20 token
     * @param _owner The owner of the token
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _maxSupply The maximum number of tokens that can be minted
     * @param _tokenPrice The price per token in Wei
     */
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _tokenPrice
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        require(_owner != address(0));
        owner = _owner;
        maxSupply = _maxSupply;
        tokenPrice = _tokenPrice;
    }

    /**
     * @notice Mints tokens to a specified account
     * @param account The account to mint tokens to
     * @param amount The amount of tokens to mint
     * @dev This function requires the contract to have a non-zero token price
     * and for the message value to cover the price of the desired amount of
     * tokens
     */
    function mint(address account, uint256 amount) public payable nonReentrant {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");

        if (
            tokenPrice > 0 &&
            msg.value != (amount * tokenPrice) / 10 ** decimals()
        ) {
            revert("Insufficient Ether sent");
        }

        _mint(account, amount);
    }

    /// @notice Receives Ether and mints tokens according to the token price
    receive() external payable {
        require(tokenPrice > 0, "Cannot send ETH with zero token price");
        mint(msg.sender, (msg.value * 10 ** decimals()) / tokenPrice);
    }

    /// @notice Withdraws all Ether in the contract to a owner address
    function withdraw() public nonReentrant {
        (bool sent, ) = payable(address(owner)).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }
}

/// @title A token contract for ERC721 tokens with minting and withdrawal functionality
contract ERC721Toqen is ERC721, ReentrancyGuard {
    /// @notice The owner of the token contract
    address public immutable owner;
    /// @notice The maximum supply of tokens that can be minted
    uint256 public immutable maxSupply;
    /// @notice The price per token in Wei
    uint256 public immutable tokenPrice;

    /// @notice The base URI for token metadata
    string public baseURI;
    /// @notice The current token ID to be minted next
    uint256 public totalSupply;

    /**
     * @notice Creates a new ERC721 token
     * @param _owner The owner of the token
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _maxSupply The maximum number of tokens that can be minted
     * @param _tokenPrice The price per token in Wei
     * @param baseURI_ The base URI for token metadata
     */
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _tokenPrice,
        string memory baseURI_
    ) ERC721(_name, _symbol) {
        require(_owner != address(0));
        owner = _owner;
        maxSupply = _maxSupply;
        tokenPrice = _tokenPrice;
        baseURI = baseURI_;
    }

    /// @notice Returns the base URI for computing {tokenURI}
    /// @dev Overrides the OpenZeppelin {ERC721-_baseURI} internal function
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Mints tokens to a specified account
     * @param account The account to mint tokens to
     * @param amount The amount of tokens to mint
     * @dev This function requires the contract to have a non-zero token price
     * and for the message value to cover the price of the desired amount of
     * tokens
     */
    function mint(address account, uint256 amount) public payable nonReentrant {
        require(totalSupply + amount <= maxSupply, "Exceeds max supply");

        if (tokenPrice > 0 && msg.value != amount * tokenPrice) {
            revert("Insufficient Ether sent");
        }

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(account, ++totalSupply);
        }
    }

    /// @notice Receives Ether and mints tokens according to the token price
    receive() external payable {
        require(tokenPrice > 0, "Cannot send ETH with zero token price");
        mint(msg.sender, msg.value / tokenPrice);
    }

    /// @notice Withdraws all Ether in the contract to a owner address
    function withdraw() public nonReentrant {
        (bool sent, ) = payable(address(owner)).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }
}

/// @title A factory contract for creating and managing ERC20 and ERC721 tokens
contract Toqen {
    /// @notice Emitted when a new token contract is created
    event TokenCreated(address indexed tokenAddress, address indexed creator);

    /// @notice Creates the contract
    constructor() {}

    /**
     * @notice Creates a new ERC20 token and registers it
     * @param name The name of the ERC20 token
     * @param symbol The symbol of the ERC20 token
     * @param maxSupply The maximum number of ERC20 tokens that can be minted
     * @param tokenPrice The price per ERC20 token in Wei
     * @return token The address of the created ERC20 token contract
     * @dev This function deploys a new ERC20 token contract and registers the
     * caller as the owner of the token in the `tokenOwners` mapping.
     */
    function createERC20(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 tokenPrice
    ) public returns (ERC20Toqen token) {
        token = new ERC20Toqen(msg.sender, name, symbol, maxSupply, tokenPrice);
        emit TokenCreated(address(token), msg.sender);
    }

    /**
     * @notice Creates a new ERC721 token and registers it
     * @param name The name of the ERC721 token
     * @param symbol The symbol of the ERC721 token
     * @param maxSupply The maximum number of ERC721 tokens that can be minted
     * @param tokenPrice The price per ERC721 token in Wei
     * @param baseURI The base URI for ERC721 token metadata
     * @return token The address of the created ERC721 token contract
     * @dev This function deploys a new ERC721 token contract and registers the
     * caller as the owner of the token in the `tokenOwners` mapping.
     */
    function createERC721(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 tokenPrice,
        string memory baseURI
    ) public returns (ERC721Toqen token) {
        token = new ERC721Toqen(
            msg.sender,
            name,
            symbol,
            maxSupply,
            tokenPrice,
            baseURI
        );
        emit TokenCreated(address(token), msg.sender);
    }
}
