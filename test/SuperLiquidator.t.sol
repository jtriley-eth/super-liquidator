// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {
    SuperfluidFrameworkDeployer as SfDeployer,
    IPureSuperToken
} from "sf/utils/SuperfluidFrameworkDeployer.sol";
import {ERC1820RegistryCompiled as Reg1820} from "sf/libs/ERC1820RegistryCompiled.sol";
import {BatchLiquidator} from "sf/utils/BatchLiquidator.sol";

import "src/Deploy.sol";
import "src/Interfaces.sol";

using { create, appendArgs } for bytes;
using { compile } for Vm;

contract SuperLiquidatorTest is Test {

    SfDeployer.Framework sf;
    IPureSuperToken token;
    IBatchLiquidator liq;
    IBatchLiquidator oldLiq;

    address admin = address(0x420);
    address alice = address(0x421);
    address bob = address(0x422);
    address charlie = address(0x423);
    address dan = address(0x424);

    function setUp() public {
        vm.etch(Reg1820.at, Reg1820.bin);

        vm.startPrank(admin);

        SfDeployer _deployment = new SfDeployer();

        sf = _deployment.getFramework();

        token = _deployment.deployPureSuperToken("Test Boi", "TEST", 3_000 ether);

        token.transfer(alice, 1_000 ether);
        token.transfer(bob, 1_000 ether);
        token.transfer(charlie, 1_000 ether);

        vm.stopPrank();

        liq = IBatchLiquidator(vm.compile("huff/SuperLiquidator.huff").create({value: 0}));
        oldLiq = IBatchLiquidator(address(new BatchLiquidator()));
    }

    function testLiquidateSingleCalldata() public {
        vm.startPrank(alice);

        sf.host.callAgreement(
            sf.cfa,
            abi.encodeCall(sf.cfa.createFlow, (token, bob, int96(10_000_000), new bytes(0))),
            new bytes(0)
        );

        // should make alice insolvent.
        token.transfer(admin, token.balanceOf(alice));

        vm.stopPrank();
        vm.warp(block.timestamp + 1);

        address[] memory senders = new address[](1);
        address[] memory receivers = new address[](1);

        senders[0] = alice;
        receivers[0] = bob;

        uint256 gas = gasleft();
        liq.deleteFlows(address(sf.host), address(sf.cfa), address(token), senders, receivers);
        gas -= gasleft();
        console.log(gas);

        (, int96 flowRate, , ) = sf.cfa.getFlow(token, alice, bob);

        assertEq(flowRate, 0);
    }

    function testLiquidateMultiCalldata() public {
        vm.startPrank(alice);

        sf.host.callAgreement(
            sf.cfa,
            abi.encodeCall(sf.cfa.createFlow, (token, bob, int96(10_000_000), new bytes(0))),
            new bytes(0)
        );

        // should make alice insolvent.
        token.transfer(admin, token.balanceOf(alice));

        vm.stopPrank();

        vm.startPrank(charlie);

        sf.host.callAgreement(
            sf.cfa,
            abi.encodeCall(sf.cfa.createFlow, (token, dan, int96(10_000_000), new bytes(0))),
            new bytes(0)
        );

        // should make alice insolvent.
        token.transfer(admin, token.balanceOf(charlie));

        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        address[] memory senders = new address[](2);
        address[] memory receivers = new address[](2);

        senders[0] = alice;
        senders[1] = charlie;
        receivers[0] = bob;
        receivers[1] = dan;

        uint256 gas = gasleft();
        liq.deleteFlows(address(sf.host), address(sf.cfa), address(token), senders, receivers);
        gas -= gasleft();
        console.log(gas);

        (, int96 aliceFlowRate, , ) = sf.cfa.getFlow(token, alice, bob);
        (, int96 charlieFlowRate, , ) = sf.cfa.getFlow(token, charlie, dan);

        assertEq(aliceFlowRate, 0);
        assertEq(charlieFlowRate, 0);
    }

    function testOldLiquidateSingleCalldata() public {
        vm.startPrank(alice);

        sf.host.callAgreement(
            sf.cfa,
            abi.encodeCall(sf.cfa.createFlow, (token, bob, int96(10_000_000), new bytes(0))),
            new bytes(0)
        );

        // should make alice insolvent.
        token.transfer(admin, token.balanceOf(alice));

        vm.stopPrank();
        vm.warp(block.timestamp + 1);

        address[] memory senders = new address[](1);
        address[] memory receivers = new address[](1);

        senders[0] = alice;
        receivers[0] = bob;

        uint256 gas = gasleft();
        oldLiq.deleteFlows(address(sf.host), address(sf.cfa), address(token), senders, receivers);
        gas -= gasleft();
        console.log(gas);

        (, int96 flowRate, , ) = sf.cfa.getFlow(token, alice, bob);

        assertEq(flowRate, 0);
    }

    function testOldLiquidateMultiCalldata() public {
        vm.startPrank(alice);

        sf.host.callAgreement(
            sf.cfa,
            abi.encodeCall(sf.cfa.createFlow, (token, bob, int96(10_000_000), new bytes(0))),
            new bytes(0)
        );

        // should make alice insolvent.
        token.transfer(admin, token.balanceOf(alice));

        vm.stopPrank();

        vm.startPrank(charlie);

        sf.host.callAgreement(
            sf.cfa,
            abi.encodeCall(sf.cfa.createFlow, (token, dan, int96(10_000_000), new bytes(0))),
            new bytes(0)
        );

        // should make alice insolvent.
        token.transfer(admin, token.balanceOf(charlie));

        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        address[] memory senders = new address[](2);
        address[] memory receivers = new address[](2);

        senders[0] = alice;
        senders[1] = charlie;
        receivers[0] = bob;
        receivers[1] = dan;

        uint256 gas = gasleft();
        oldLiq.deleteFlows(address(sf.host), address(sf.cfa), address(token), senders, receivers);
        gas -= gasleft();
        console.log(gas);

        (, int96 aliceFlowRate, , ) = sf.cfa.getFlow(token, alice, bob);
        (, int96 charlieFlowRate, , ) = sf.cfa.getFlow(token, charlie, dan);

        assertEq(aliceFlowRate, 0);
        assertEq(charlieFlowRate, 0);
    }
}
