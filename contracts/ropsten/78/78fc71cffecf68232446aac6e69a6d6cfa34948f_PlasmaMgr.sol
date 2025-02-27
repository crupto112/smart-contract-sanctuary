pragma solidity ^0.4.24;
/**
* @title RLPReader
*
* RLPReader is used to read and parse RLP encoded data in memory.
*
* @author Andreas Olofsson (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0f6e616b7d6063603e36373f4f68626e6663216c6062">[email&#160;protected]</a>)
*/
library RLP {

 uint constant DATA_SHORT_START = 0x80;
 uint constant DATA_LONG_START = 0xB8;
 uint constant LIST_SHORT_START = 0xC0;
 uint constant LIST_LONG_START = 0xF8;

 uint constant DATA_LONG_OFFSET = 0xB7;
 uint constant LIST_LONG_OFFSET = 0xF7;


 struct RLPItem {
     uint _unsafe_memPtr;    // Pointer to the RLP-encoded bytes.
     uint _unsafe_length;    // Number of bytes. This is the full length of the string.
 }

 struct Iterator {
     RLPItem _unsafe_item;   // Item that&#39;s being iterated over.
     uint _unsafe_nextPtr;   // Position of the next item in the list.
 }

 /* Iterator */

 function next(Iterator memory self) internal constant returns (RLPItem memory subItem) {
     if(hasNext(self)) {
         uint ptr = self._unsafe_nextPtr;
         uint itemLength = _itemLength(ptr);
         subItem._unsafe_memPtr = ptr;
         subItem._unsafe_length = itemLength;
         self._unsafe_nextPtr = ptr + itemLength;
     }
     else
         assert;
 }

 function next(Iterator memory self, bool strict) internal constant returns (RLPItem memory subItem) {
     subItem = next(self);
     if(strict && !_validate(subItem))
         assert;
     return;
 }

 function hasNext(Iterator memory self) internal constant returns (bool) {
     var item = self._unsafe_item;
     return self._unsafe_nextPtr < item._unsafe_memPtr + item._unsafe_length;
 }

 /* RLPItem */

 /// @dev Creates an RLPItem from an array of RLP encoded bytes.
 /// @param self The RLP encoded bytes.
 /// @return An RLPItem
 function toRLPItem(bytes memory self) internal constant returns (RLPItem memory) {
     uint len = self.length;
     if (len == 0) {
         return RLPItem(0, 0);
     }
     uint memPtr;
     assembly {
         memPtr := add(self, 0x20)
     }
     return RLPItem(memPtr, len);
 }

 /// @dev Creates an RLPItem from an array of RLP encoded bytes.
 /// @param self The RLP encoded bytes.
 /// @param strict Will throw if the data is not RLP encoded.
 /// @return An RLPItem
 function toRLPItem(bytes memory self, bool strict) internal constant returns (RLPItem memory) {
     var item = toRLPItem(self);
     if(strict) {
         uint len = self.length;
         if(_payloadOffset(item) > len)
             assert;
         if(_itemLength(item._unsafe_memPtr) != len)
             assert;
         if(!_validate(item))
             assert;
     }
     return item;
 }

 /// @dev Check if the RLP item is null.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is null.
 function isNull(RLPItem memory self) internal constant returns (bool ret) {
     return self._unsafe_length == 0;
 }

 /// @dev Check if the RLP item is a list.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is a list.
 function isList(RLPItem memory self) internal constant returns (bool ret) {
     if (self._unsafe_length == 0)
         return false;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         ret := iszero(lt(byte(0, mload(memPtr)), 0xC0))
     }
 }

 /// @dev Check if the RLP item is data.
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is data.
 function isData(RLPItem memory self) internal constant returns (bool ret) {
     if (self._unsafe_length == 0)
         return false;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         ret := lt(byte(0, mload(memPtr)), 0xC0)
     }
 }

 /// @dev Check if the RLP item is empty (string or list).
 /// @param self The RLP item.
 /// @return &#39;true&#39; if the item is null.
 function isEmpty(RLPItem memory self) internal constant returns (bool ret) {
     if(isNull(self))
         return false;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     return (b0 == DATA_SHORT_START || b0 == LIST_SHORT_START);
 }

 /// @dev Get the number of items in an RLP encoded list.
 /// @param self The RLP item.
 /// @return The number of items.
 function items(RLPItem memory self) internal constant returns (uint) {
     if (!isList(self))
         return 0;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     uint pos = memPtr + _payloadOffset(self);
     uint last = memPtr + self._unsafe_length - 1;
     uint itms;
     while(pos <= last) {
         pos += _itemLength(pos);
         itms++;
     }
     return itms;
 }

 /// @dev Create an iterator.
 /// @param self The RLP item.
 /// @return An &#39;Iterator&#39; over the item.
 function iterator(RLPItem memory self) internal constant returns (Iterator memory it) {
     if (!isList(self))
         assert;
     uint ptr = self._unsafe_memPtr + _payloadOffset(self);
     it._unsafe_item = self;
     it._unsafe_nextPtr = ptr;
 }

 /// @dev Return the RLP encoded bytes.
 /// @param self The RLPItem.
 /// @return The bytes.
 function toBytes(RLPItem memory self) internal constant returns (bytes memory bts) {
     uint len = self._unsafe_length;
     if (len == 0)
         return;
     bts = new bytes(len);
     _copyToBytes(self._unsafe_memPtr, bts, len);
 }

 /// @dev Decode an RLPItem into bytes. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toData(RLPItem memory self) internal constant returns (bytes memory bts) {
     if(!isData(self))
         assert;
     var (rStartPos, len) = _decode(self);
     bts = new bytes(len);
     _copyToBytes(rStartPos, bts, len);
 }

 /// @dev Get the list of sub-items from an RLP encoded list.
 /// Warning: This is inefficient, as it requires that the list is read twice.
 /// @param self The RLP item.
 /// @return Array of RLPItems.
 function toList(RLPItem memory self) internal constant returns (RLPItem[] memory list) {
     if(!isList(self))
         assert;
     var numItems = items(self);
     list = new RLPItem[](numItems);
     var it = iterator(self);
     uint idx;
     while(hasNext(it)) {
         list[idx] = next(it);
         idx++;
     }
 }

 /// @dev Decode an RLPItem into an ascii string. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toAscii(RLPItem memory self) internal constant returns (string memory str) {
     if(!isData(self))
         assert;
     var (rStartPos, len) = _decode(self);
     bytes memory bts = new bytes(len);
     _copyToBytes(rStartPos, bts, len);
     str = string(bts);
 }

 /// @dev Decode an RLPItem into a uint. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toUint(RLPItem memory self) internal constant returns (uint data) {
     if(!isData(self))
         assert;
     var (rStartPos, len) = _decode(self);
     if (len > 32 || len == 0)
         throw;
     assembly {
         data := div(mload(rStartPos), exp(256, sub(32, len)))
     }
 }

 /// @dev Decode an RLPItem into a boolean. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toBool(RLPItem memory self) internal constant returns (bool data) {
     if(!isData(self))
         assert;
     var (rStartPos, len) = _decode(self);
     if (len != 1)
         assert;
     uint temp;
     assembly {
         temp := byte(0, mload(rStartPos))
     }
     if (temp > 1)
         assert;
     return temp == 1 ? true : false;
 }

 /// @dev Decode an RLPItem into a byte. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toByte(RLPItem memory self) internal constant returns (byte data) {
     if(!isData(self))
         assert;
     var (rStartPos, len) = _decode(self);
     if (len != 1)
         assert;
     uint temp;
     assembly {
         temp := byte(0, mload(rStartPos))
     }
     return byte(temp);
 }

 /// @dev Decode an RLPItem into an int. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toInt(RLPItem memory self) internal constant returns (int data) {
     return int(toUint(self));
 }

 /// @dev Decode an RLPItem into a bytes32. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toBytes32(RLPItem memory self) internal constant returns (bytes32 data) {
     return bytes32(toUint(self));
 }

 /// @dev Decode an RLPItem into an address. This will not work if the
 /// RLPItem is a list.
 /// @param self The RLPItem.
 /// @return The decoded string.
 function toAddress(RLPItem memory self) internal constant returns (address data) {
     if(!isData(self))
         assert;
     var (rStartPos, len) = _decode(self);
     if (len != 20)
         assert;
     assembly {
         data := div(mload(rStartPos), exp(256, 12))
     }
 }

 // Get the payload offset.
 function _payloadOffset(RLPItem memory self) private constant returns (uint) {
     if(self._unsafe_length == 0)
         return 0;
     uint b0;
     uint memPtr = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     if(b0 < DATA_SHORT_START)
         return 0;
     if(b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
         return 1;
     if(b0 < LIST_SHORT_START)
         return b0 - DATA_LONG_OFFSET + 1;
     return b0 - LIST_LONG_OFFSET + 1;
 }

 // Get the full length of an RLP item.
 function _itemLength(uint memPtr) private constant returns (uint len) {
     uint b0;
     assembly {
         b0 := byte(0, mload(memPtr))
     }
     if (b0 < DATA_SHORT_START)
         len = 1;
     else if (b0 < DATA_LONG_START)
         len = b0 - DATA_SHORT_START + 1;
     else if (b0 < LIST_SHORT_START) {
         assembly {
             let bLen := sub(b0, 0xB7) // bytes length (DATA_LONG_OFFSET)
             let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
             len := add(1, add(bLen, dLen)) // total length
         }
     }
     else if (b0 < LIST_LONG_START)
         len = b0 - LIST_SHORT_START + 1;
     else {
         assembly {
             let bLen := sub(b0, 0xF7) // bytes length (LIST_LONG_OFFSET)
             let dLen := div(mload(add(memPtr, 1)), exp(256, sub(32, bLen))) // data length
             len := add(1, add(bLen, dLen)) // total length
         }
     }
 }

 // Get start position and length of the data.
 function _decode(RLPItem memory self) private constant returns (uint memPtr, uint len) {
     if(!isData(self))
         assert;
     uint b0;
     uint start = self._unsafe_memPtr;
     assembly {
         b0 := byte(0, mload(start))
     }
     if (b0 < DATA_SHORT_START) {
         memPtr = start;
         len = 1;
         return;
     }
     if (b0 < DATA_LONG_START) {
         len = self._unsafe_length - 1;
         memPtr = start + 1;
     } else {
         uint bLen;
         assembly {
             bLen := sub(b0, 0xB7) // DATA_LONG_OFFSET
         }
         len = self._unsafe_length - 1 - bLen;
         memPtr = start + bLen + 1;
     }
     return;
 }

 // Assumes that enough memory has been allocated to store in target.
 function _copyToBytes(uint btsPtr, bytes memory tgt, uint btsLen) private constant {
     // Exploiting the fact that &#39;tgt&#39; was the last thing to be allocated,
     // we can write entire words, and just overwrite any excess.
     assembly {
         {
                 let i := 0 // Start at arr + 0x20
                 let words := div(add(btsLen, 31), 32)
                 let rOffset := btsPtr
                 let wOffset := add(tgt, 0x20)
             tag_loop:
                 jumpi(end, eq(i, words))
                 {
                     let offset := mul(i, 0x20)
                     mstore(add(wOffset, offset), mload(add(rOffset, offset)))
                     i := add(i, 1)
                 }
                 jump(tag_loop)
             end:
                 mstore(add(tgt, add(0x20, mload(tgt))), 0)
         }
     }
 }

 // Check that an RLP item is valid.
     function _validate(RLPItem memory self) private constant returns (bool ret) {
         // Check that RLP is well-formed.
         uint b0;
         uint b1;
         uint memPtr = self._unsafe_memPtr;
         assembly {
             b0 := byte(0, mload(memPtr))
             b1 := byte(1, mload(memPtr))
         }
         if(b0 == DATA_SHORT_START + 1 && b1 < DATA_SHORT_START)
             return false;
         return true;
     }
}

library MinHeapLib {
    struct Heap {
        uint256[] data;
    }

    function add(Heap storage _heap, uint256 value) internal {
        uint index = _heap.data.length;
        _heap.data.length += 1;
        _heap.data[index] = value;

        // Fix the min heap if it is violated.
        while (index != 0 && _heap.data[index] < _heap.data[(index - 1) / 2]) {
            uint256 temp = _heap.data[index];
            _heap.data[index] = _heap.data[(index - 1) / 2];
            _heap.data[(index - 1) / 2] = temp;
            index = (index - 1) / 2;
        }
    }

    function peek(Heap storage _heap) view internal returns (uint256 value) {
        require(_heap.data.length > 0);
        return _heap.data[0];
    }

    function pop(Heap storage _heap) internal returns (uint256 value) {
        require(_heap.data.length > 0);
        uint256 root = _heap.data[0];
        _heap.data[0] = _heap.data[_heap.data.length - 1];
        _heap.data.length -= 1;
        heapify(_heap, 0);
        return root;
    }

    function heapify(Heap storage _heap, uint i) internal {
        uint left = 2 * i + 1;
        uint right = 2 * i + 2;
        uint smallest = i;
        if (left < _heap.data.length && _heap.data[left] < _heap.data[i]) {
            smallest = left;
        }
        if (right < _heap.data.length && _heap.data[right] < _heap.data[smallest]) {
            smallest = right;
        }
        if (smallest != i) {
            uint256 temp = _heap.data[i];
            _heap.data[i] = _heap.data[smallest];
            _heap.data[smallest] = temp;
            heapify(_heap, smallest);
        }
    }

    function isEmpty(Heap storage _heap) view internal returns (bool empty) {
        return _heap.data.length == 0;
    }
}

library ArrayLib {
    function remove(uint256[] storage _array, uint256 _value)
        internal
        returns (bool success)
    {
        int256 index = indexOf(_array, _value);
        if (index == -1) {
            return false;
        }
        uint256 lastElement = _array[_array.length - 1];
        _array[uint256(index)] = lastElement;

        delete _array[_array.length - 1];
        _array.length -= 1;
        return true;
    }

    function indexOf(uint256[] _array, uint256 _value)
        internal
        pure
        returns(int256 index)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _value) {
                return int256(i);
            }
        }
        return -1;
    }
}


contract PlasmaMgr {

	struct BlockHeader {
        uint256 blockNumber;
        bytes32 previousHash;
        bytes32 merkleRoot;
        bytes32 r;
        bytes32 s;
        uint8 v;
		uint256 timeSubmitted;
    }
	
	uint256 exitAgeOffset;
    uint256 exitWaitOffset;
    uint32 constant blockHeaderLength = 161;
	bytes constant PersonalMessagePrefixBytes = "\x19Ethereum Signed Message:\n96";
	
	uint256 public lastBlockNumber;
	mapping(uint256 => BlockHeader) public headers;
	
	
	constructor() public {
       
        lastBlockNumber = 0;

    }
    
    function RemoveAllHeaders() public {
        while(lastBlockNumber>0)
        {
            delete headers[lastBlockNumber];
            lastBlockNumber--;
        }
        require(lastBlockNumber == 0);
    }
    
    function submitFakeHeader() public returns (bool success) {
        
        uint256 blockNumber;
        bytes32 previousHash;
        bytes32 merkleRoot;
        bytes32 sigR;
        bytes32 sigS;
        bytes1 sigV;
        
        BlockHeader memory newHeader = BlockHeader({
            blockNumber: uint8(blockNumber),
            previousHash: previousHash,
            merkleRoot: merkleRoot,
            r: sigR,
            s: sigS,
            v: uint8(sigV),
            timeSubmitted: now
        });
        blockNumber = lastBlockNumber + 1;
        headers[uint8(blockNumber)] = newHeader;

        // Increment the block number by 1 and reset the transaction counter.
        lastBlockNumber += 1;
        return true;
    }
	
	event HeaderSubmittedEvent(address signer, uint32 blockNumber);
	function submitBlockHeader(bytes header) public returns (bool success) {
       // require(header.length == blockHeaderLength);

        bytes32 blockNumber;
        bytes32 previousHash;
        bytes32 merkleRoot;
        bytes32 sigR;
        bytes32 sigS;
        bytes1 sigV;
        assembly {
            let data := add(header, 0x20)
            blockNumber := mload(data)
            previousHash := mload(add(data, 32))
            merkleRoot := mload(add(data, 64))
            sigR := mload(add(data, 96))
            sigS := mload(add(data, 128))
            sigV := mload(add(data, 160))
            if lt(sigV, 27) { sigV := add(sigV, 27) }
        }
      
        // Check the block number.
        require(uint8(blockNumber) == lastBlockNumber + 1);

        BlockHeader memory newHeader = BlockHeader({
            blockNumber: uint8(blockNumber),
            previousHash: previousHash,
            merkleRoot: merkleRoot,
            r: sigR,
            s: sigS,
            v: uint8(sigV),
            timeSubmitted: now
        });
        headers[uint8(blockNumber)] = newHeader;

        // Increment the block number by 1 and reset the transaction counter.
        lastBlockNumber += 1;
        //txCounter = 0;

        HeaderSubmittedEvent(msg.sender, uint8(blockNumber));

      
        return true;
    }


}