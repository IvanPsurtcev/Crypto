pragma solidity 0.8.1;

contract MyToken {
    string public constant name = "i.23";
    string public constant symbol = "I23";
    uint8 public constant decimals = 18; // хранит кол-во знаков после запятой

    uint public totalSupply; // хранит кол-во всех выпущенных токенов

    mapping (address => uint) balances; // массив где хранится кому и сколько принадлежит токенов

    mapping (address => mapping(address => uint)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _from, address indexed _to, uint _value);

    // эмиссия токенов
    function mint(address to, uint value) public {
        require(totalSupply + value >= totalSupply && balances[to] + value >= balances[to]);
        balances[to] += value;
        totalSupply += value;
    }

    // показывает баланс
    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    //трансзакции
    function transfer(address _to, uint _value) public {
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
    function transferFrom(address _from, address _to, uint _value) public {
        require(balances[_from] >= _value && balances[_to] + _value >= balances[_to] && allowed[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender,  _value);
    }
}