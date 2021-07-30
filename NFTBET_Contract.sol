/**
 *Submitted for verification at hecoinfo.com on 2021-07-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.1 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    require(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 is ERC20Basic {
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address private _owner;

    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        // emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferOwnership(address newOwner) public onlyOwner {
    //     _transferOwnership(newOwner);
    // }

    // /**
    //  * @dev Transfers ownership of the contract to a new account (`newOwner`).
    //  */
    // function _transferOwnership(address newOwner) internal {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     emit OwnershipTransferred(_owner, newOwner);
    //     _owner = newOwner;
    // }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 _totalSupply;
  
  address _stakeAddress;
  mapping(address => bool) public txWhiteList;
  bool needGas = false;
  function needGasOnOff(bool _needGas) external onlyOwner {
      needGas = _needGas;
  }
  function addTxWhiteList(address _address) external onlyOwner {
      txWhiteList[_address] = true;
  }
  function subTxWhiteList(address _address) external onlyOwner {
      delete txWhiteList[_address];
  }
  function updateStakeAddress(address _address) external onlyOwner {
      _stakeAddress = _address;
  }
  function stakeAddress() public view returns (address) {
    return (_stakeAddress);
  }
  
  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    if(msg.data.length < size + 4) {
      revert();
    }
    _;
  }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }
  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) override returns (bool) {
    if (!needGas || address(msg.sender) == address(_stakeAddress)) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    handleTx(msg.sender, _to, _value);
    return true;
  }
  
  function handleTx(address _from, address _to, uint256 _value) internal {
    require(_value <= balances[_from].div(5), "transfer no more than balance 20%");
    uint256 gas = _value.div(10);
    emit Transfer(_from, _to, _value);
    
    uint256 sendGas = 0;
    uint256 from_value = _value;
    if (!txWhiteList[_from]) {
        sendGas = sendGas.add(gas);
        from_value = _value.add(gas);
        emit Transfer(_from, _stakeAddress, gas);
    }
    balances[_from] = balances[_from].sub(from_value);
    
    uint256 to_value = _value;
    if (!txWhiteList[_to]) {
        sendGas = sendGas.add(gas);
        to_value = _value.sub(gas);
        emit Transfer(_to, _stakeAddress, gas);
    }
    balances[_to] = balances[_to].add(to_value);
    
    if (sendGas > 0) {
        balances[_stakeAddress] = balances[_stakeAddress].add(gas.mul(2));
        ANftBetStake nftBetStake = ANftBetStake(_stakeAddress);
        nftBetStake.sendTxGas(sendGas);
    }
  }

  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return balances[_owner];
  }
}


interface ANftBetStake  {
    function sendTxGas(uint256 gas) external;
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is ERC20, BasicToken {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) override returns (bool) {
    require(_to != address(0));
    require(_value <= allowed[_from][msg.sender]);
    if (!needGas) {
        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    handleTx(_from, _to, _value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) override returns (bool) {
    require(_spender != address(0));
    // require(_value <= balances[msg.sender]);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view override returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_spender != address(0));
    // require(allowed[msg.sender][_spender].add(_addedValue) <= balances[msg.sender]);
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_spender != address(0));
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title SimpleToken
 * @dev ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract AMyToken is StandardToken {

    string public constant symbol = "BET";
    string public constant name = "NFTBET";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 2 * (10 ** 8) * (10 ** uint256(decimals));
    // uint256 public constant INITIAL_SUPPLY = 100 * (10 ** 4) * (10 ** uint256(decimals));

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor() public{
        
        _stakeAddress = 0x0C841a1664bb2804cea9356243c31D06B4dcD0BB;    
        address buyBackAddress = 0x07A7c48453aC112cc9fc2B35B158798317fc8506;
        address systemAddress = 0xC4311A26C8406664f4936e5777A7D1077f002387;
        txWhiteList[_stakeAddress] = true;
        txWhiteList[buyBackAddress] = true;
        txWhiteList[systemAddress] = true;
        txWhiteList[address(this)] = true;
        txWhiteList[msg.sender] = true;
        _totalSupply = INITIAL_SUPPLY;
        balances[_stakeAddress] = INITIAL_SUPPLY*90/100;
        emit Transfer(address(0x0), _stakeAddress, INITIAL_SUPPLY*90/100);
        balances[buyBackAddress] = INITIAL_SUPPLY*9/100;
        emit Transfer(address(0x0), buyBackAddress, INITIAL_SUPPLY*9/100);
        balances[systemAddress] = INITIAL_SUPPLY*1/100;
        emit Transfer(address(0x0), systemAddress, INITIAL_SUPPLY*1/100);
    }
}