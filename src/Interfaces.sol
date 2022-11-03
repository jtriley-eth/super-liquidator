// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBatchLiquidator {
    function deleteFlows(
        address host,
        address cfa,
        address token,
        address[] calldata senders,
        address[] calldata receivers
    ) external;
}
