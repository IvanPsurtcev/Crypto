pragma solidity 0.8.0;

contract Insurance {
    address payable public hospital;
    address payable public insurer;

    struct Record {
        address Addr;
        uint256 ID;
        string Name;
        string date;
        uint256 price;
        bool isValue;
        uint256 signatureCount;
        mapping(address => uint256) signatures;
    }

    modifier signOnly {
        require (msg.sender == hospital || msg.sender == insurer);
        _;
    }

    constructor() public {
        hospital = 0x18b8Aae97Dfa416EF9F933562d6F8070dA1E3141;
        insurer = 0x18b8Aae97Dfa416EF9F933562d6F8070dA1E3141; //TODO
    }

    mapping(uint256 => Record) public all_records;
    uint256[] public recordsArr;

    event recordCreated(uint256 ID, string testName, string date, uint256 price);
    event recordSigned(uint256 ID, string testName, string date, uint256 price);

    function newRecord(uint256 _ID, string memory _Name, string memory _date, uint256 price) public {
        Record storage newRecord = all_records[_ID];
        require(!all_records[_ID].isValue);
        newRecord.Addr = msg.sender;
        newRecord.ID = _ID;
        newRecord.Name = _Name;
        newRecord.date = _date;
        newRecord.price = price;
        newRecord.isValue = true;
        newRecord.signatureCount = 0;
        recordsArr.push(_ID);
        emit recordCreated(newRecord.ID, _Name, _date, price);
    }

    function signRecord(uint256 _ID) signOnly public payable {
        Record storage records = all_records[_ID];
        require(records.signatures[msg.sender] != 1);
        records.signatures[msg.sender] = 1;
        records.signaturesCount++; //TODO
        emit recordSigned(records.ID, records.Name, records.date, records.price);
        if(records.signatureCount == 2) {
            hospital.transfer(address(this).balance);
        }
    }
}
