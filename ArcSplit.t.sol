// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ArcSplit.sol";

contract ArcSplitTest is Test {
    ArcSplit splitter;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);

    function setUp() public {
        splitter = new ArcSplit();
        vm.deal(address(this), 100 ether);
    }

    receive() external payable {}

    function testSplitEven() public {
        address[] memory r = new address[](2);
        r[0] = alice;
        r[1] = bob;
        uint256[] memory s = new uint256[](2);
        s[0] = 1;
        s[1] = 1;

        uint256 a0 = alice.balance;
        uint256 b0 = bob.balance;
        splitter.split{value: 10 ether}(r, s);

        assertEq(alice.balance - a0, 5 ether);
        assertEq(bob.balance - b0, 5 ether);
        assertEq(address(splitter).balance, 0);
    }

    function testSplitWeightedWithDustRefund() public {
        address[] memory r = new address[](3);
        r[0] = alice;
        r[1] = bob;
        r[2] = carol;
        uint256[] memory s = new uint256[](3);
        s[0] = 1;
        s[1] = 2;
        s[2] = 3; // total 6 shares of 10 ether -> 1.666..., 3.333..., 5.0

        uint256 before = address(this).balance;
        splitter.split{value: 10 ether}(r, s);

        uint256 expA = (uint256(10 ether) * 1) / 6;
        uint256 expB = (uint256(10 ether) * 2) / 6;
        uint256 expC = (uint256(10 ether) * 3) / 6;
        assertEq(alice.balance, expA);
        assertEq(bob.balance, expB);
        assertEq(carol.balance, expC);
        // dust refunded: 10 - (1.666.. + 3.333.. + 5.0) truncated parts
        uint256 distributed = expA + expB + expC;
        assertEq(address(this).balance, before - distributed);
        assertEq(address(splitter).balance, 0);
    }

    function testSplitSingleRecipient() public {
        address[] memory r = new address[](1);
        r[0] = alice;
        uint256[] memory s = new uint256[](1);
        s[0] = 7;

        uint256 a0 = alice.balance;
        splitter.split{value: 3 ether}(r, s);
        assertEq(alice.balance - a0, 3 ether);
    }

    function testRevertLengthMismatch() public {
        address[] memory r = new address[](2);
        r[0] = alice;
        r[1] = bob;
        uint256[] memory s = new uint256[](1);
        s[0] = 1;
        vm.expectRevert(ArcSplit.LengthMismatch.selector);
        splitter.split{value: 1 ether}(r, s);
    }

    function testRevertNoRecipients() public {
        address[] memory r = new address[](0);
        uint256[] memory s = new uint256[](0);
        vm.expectRevert(ArcSplit.NoRecipients.selector);
        splitter.split{value: 1 ether}(r, s);
    }

    function testRevertZeroAddress() public {
        address[] memory r = new address[](2);
        r[0] = alice;
        r[1] = address(0);
        uint256[] memory s = new uint256[](2);
        s[0] = 1;
        s[1] = 1;
        vm.expectRevert(ArcSplit.ZeroAddress.selector);
        splitter.split{value: 1 ether}(r, s);
    }

    function testRevertNoShares() public {
        address[] memory r = new address[](2);
        r[0] = alice;
        r[1] = bob;
        uint256[] memory s = new uint256[](2);
        s[0] = 0;
        s[1] = 0;
        vm.expectRevert(ArcSplit.NoShares.selector);
        splitter.split{value: 1 ether}(r, s);
    }

    function testSweepOnlyOwner() public {
        // force ether in
        (bool ok, ) = address(splitter).call{value: 1 ether}("");
        assertTrue(ok);
        vm.prank(alice);
        vm.expectRevert(ArcSplit.NotOwner.selector);
        splitter.sweep();
        uint256 ownerBal = splitter.owner().balance;
        splitter.sweep();
        assertEq(splitter.owner().balance - ownerBal, 1 ether);
    }

    function testSplitEmitsEvent() public {
        address[] memory r = new address[](2);
        r[0] = alice;
        r[1] = bob;
        uint256[] memory s = new uint256[](2);
        s[0] = 1;
        s[1] = 3;

        uint256[] memory expected = new uint256[](2);
        expected[0] = (4 ether * 1) / 4;
        expected[1] = (4 ether * 3) / 4;

        vm.expectEmit(true, false, false, true);
        emit ArcSplit.Split(address(this), r, expected, 0);
        splitter.split{value: 4 ether}(r, s);
    }
}
