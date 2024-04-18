// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Toqen, ERC20Toqen, ERC721Toqen} from "../src/Toqen.sol";

contract ToqenTest is Test {
    Toqen public toqen;

    function setUp() public {
        toqen = new Toqen();
    }

    function test_Paid_Mint_ERC20() public {
        ERC20Toqen erc20 = toqen.createERC20("Test", "TST", 1_000 ether, 111); // 1 TST = 111 wei
        erc20.mint{value: 100 * 111}(address(1), 100 ether);
        assertEq(erc20.balanceOf(address(1)), 100 ether);
    }

    function test_Paid_Mint_ERC721() public {
        ERC721Toqen erc721 = toqen.createERC721("Test", "TST", 1_000, 1 ether, "BaseURI");
        erc721.mint{value: 2 ether}(address(1), 2);
        assertEq(erc721.ownerOf(2), address(1));
        assertEq(erc721.baseURI(), "BaseURI");
    }

    function test_Receive_Mint_ERC20() public {
        ERC20Toqen erc20 = toqen.createERC20("Test", "TST", 1_000 ether, 112 ether); // 1 TST = 112 eth
        (bool sent, ) = payable(erc20).call{value: 112 ether}("");
        require(sent, "Failed to send Ether");
        assertEq(erc20.balanceOf(address(this)), 1 ether);
    }

    function test_Receive_Mint_ERC721() public {
        ERC721Toqen erc721 = toqen.createERC721("Test", "TST", 1_000, 1, "BaseURI");
        vm.deal(address(1), 1 ether);
        vm.prank(address(1));
        (bool sent, ) = payable(erc721).call{value: 2}("");
        require(sent, "Failed to send Ether");
        assertEq(erc721.ownerOf(2), address(1));
    }

    function test_Withdraw_ERC20() public {
        vm.prank(address(2));
        ERC20Toqen erc20 = toqen.createERC20("Test", "TST", 1_000, 33 ether); // 1 TST wei = 33 eth
        erc20.mint{value: 10 * 33}(address(1), 10);
        erc20.withdraw();
        assertEq(address(2).balance, 330);
    }

    function test_Withdraw_ERC721() public {
        vm.prank(address(2));
        ERC721Toqen erc721 = toqen.createERC721("Test", "TST", 1_000, 1 ether, "BaseURI");
        erc721.mint{value: 2 ether}(address(1), 2);
        erc721.withdraw();
        assertEq(address(2).balance, 2 ether);
    }

    function test_Free_Mint_ERC20() public {
        ERC20Toqen erc20 = toqen.createERC20("Test", "TST", 1_000, 0);
        erc20.mint(address(1), 100);
        assertEq(erc20.balanceOf(address(1)), 100);
    }

    function test_Free_Mint_ERC721() public {
        ERC721Toqen erc721 = toqen.createERC721("Test", "TST", 1_000, 0, "BaseURI");
        erc721.mint(address(1), 1);
        erc721.mint(address(1), 1);
        assertEq(erc721.ownerOf(2), address(1));
    }
}
