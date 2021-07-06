pragma solidity 0.8.1;

library WorkWithArray {
    function Search(uint [] storage self, uint _value) view public returns(uint) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == _value) return i;
        }
        return uint(-1);
    }

    function remove(uint [] storage self, uint index) view public returns(uint) {
        require(index >= 0);
        for (uint i = index; i < self.length; i++) {
            self[i] = self [i+1];
        }
        delete self[self.length-1];
        self.length--;
    }
}

contract lesson {
    using WorkWithArray for uint [];

    uint [] public array;

    function push(uint elem) public {
        array.push(elem);
    }

    function replace(uint oldElem, uint newElem) public {
        uint position = array.search(oldElem);

        if(position == uint(-1)) {
            array.push(newElem);
        }
        else {
            array[position] = newElem;
        }
    }

    function findAndDelete(uint elem) public {
        array.remove(array.search(elem));
    }

    function getArray() public view returns(uint [] memory) {
        return array;
    }
}