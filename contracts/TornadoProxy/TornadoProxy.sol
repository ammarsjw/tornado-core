// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./ITornadoInstance.sol";
import "./ITornadoTrees.sol";

contract TornadoProxy {
  using SafeERC20 for IERC20;

  event EncryptedNote(address indexed sender, bytes encryptedNote);
  event InstanceStateUpdate(ITornadoInstance indexed instance, InstanceState state);

  enum InstanceState { Disabled, Enabled, Mineable }

  struct Instance {
    bool isERC20;
    IERC20 token;
    InstanceState state;
  }

  struct Tornado {
    ITornadoInstance addr;
    Instance instance;
  }

  ITornadoTrees public tornadoTrees;
  address public immutable governance;
  mapping(ITornadoInstance => Instance) public instances;

  modifier onlyGovernance() {
    require(msg.sender == governance, "Not authorized");
    _;
  }

  constructor(
    // address _tornadoTrees,
    address _governance
    // Tornado[] memory _instances
  ) public {
    // tornadoTrees = ITornadoTrees(_tornadoTrees);
    governance = _governance;

    // for (uint256 i = 0; i < _instances.length; i++) {
    //   _updateInstance(_instances[i]);
    // }

    Tornado memory instance;
    instance.addr = ITornadoInstance(0x67698727EEF9fe6D5DC1A48aF1C4935F36975a2F);
    instance.instance.isERC20 = false;
    instance.instance.token = IERC20(0x0000000000000000000000000000000000000000);
    instance.instance.state = InstanceState.Enabled;

    _updateInstance(instance);
  }

  function deposit(
    ITornadoInstance _tornado,
    bytes32 _commitment,
    bytes calldata _encryptedNote
  ) external payable {
    Instance memory instance = instances[_tornado];
    require(instance.state != InstanceState.Disabled, "The instance is not supported");

    if (instance.isERC20) {
      instance.token.safeTransferFrom(msg.sender, address(this), _tornado.denomination());
    }
    _tornado.deposit{ value: msg.value }(_commitment);

    // if (instance.state == InstanceState.Mineable) {
    //   tornadoTrees.registerDeposit(address(_tornado), _commitment);
    // }
    emit EncryptedNote(msg.sender, _encryptedNote);
  }

  function withdraw(
    ITornadoInstance _tornado,
    bytes calldata _proof,
    bytes32 _root,
    bytes32 _nullifierHash,
    address payable _recipient,
    address payable _relayer,
    uint256 _fee,
    uint256 _refund
  ) external payable {
    Instance memory instance = instances[_tornado];
    require(instance.state != InstanceState.Disabled, "The instance is not supported");

    _tornado.withdraw{ value: msg.value }(_proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
    // if (instance.state == InstanceState.Mineable) {
    //   tornadoTrees.registerWithdrawal(address(_tornado), _nullifierHash);
    // }
  }

  function backupNotes(bytes[] calldata _encryptedNotes) external {
    for (uint256 i = 0; i < _encryptedNotes.length; i++) {
      emit EncryptedNote(msg.sender, _encryptedNotes[i]);
    }
  }

  function updateInstance(Tornado calldata _tornado) external onlyGovernance {
    _updateInstance(_tornado);
  }

  function setTornadoTreesContract(address _tornadoTrees) external onlyGovernance {
    tornadoTrees = ITornadoTrees(_tornadoTrees);
  }

  /// @dev Method to claim junk and accidentally sent tokens
  function rescueTokens(
    IERC20 _token,
    address payable _to,
    uint256 _balance
  ) external onlyGovernance {
    require(_to != address(0), "TORN: can not send to zero address");

    if (_token == IERC20(0)) {
      // for Ether
      uint256 totalBalance = address(this).balance;
      uint256 balance = _balance == 0 ? totalBalance : Math.min(totalBalance, _balance);
      _to.transfer(balance);
    } else {
      // any other erc20
      uint256 totalBalance = _token.balanceOf(address(this));
      uint256 balance = _balance == 0 ? totalBalance : Math.min(totalBalance, _balance);
      require(balance > 0, "TORN: trying to send 0 balance");
      _token.safeTransfer(_to, balance);
    }
  }

  function _updateInstance(Tornado memory _tornado) internal {
    instances[_tornado.addr] = _tornado.instance;
    if (_tornado.instance.isERC20) {
      IERC20 token = IERC20(_tornado.addr.token());
      require(token == _tornado.instance.token, "Incorrect token");
      uint256 allowance = token.allowance(address(this), address(_tornado.addr));

      if (_tornado.instance.state != InstanceState.Disabled && allowance == 0) {
        token.safeApprove(address(_tornado.addr), uint256(-1));
      } else if (_tornado.instance.state == InstanceState.Disabled && allowance != 0) {
        token.safeApprove(address(_tornado.addr), 0);
      }
    }
    emit InstanceStateUpdate(_tornado.addr, _tornado.instance.state);
  }
}