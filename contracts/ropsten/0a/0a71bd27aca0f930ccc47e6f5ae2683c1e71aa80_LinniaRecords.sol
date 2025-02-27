pragma solidity ^0.4.13;

contract LinniaWhitelistI {

    event LogExpertScoreUpdated(
    address indexed user,
    uint indexed score);
    
    mapping(address => uint) public expertScores;
    
    function expertScoreOf(address user) public view returns(uint); 

}

contract IrisScoreProviderI {

    /// report the IRIS score for the dasaHash records
    /// @param dataHash the hash of the data to be scored
    function report(bytes32 dataHash)
        public
        view
        returns (uint256);
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Destructible is Ownable {

  constructor() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract LinniaHub is Ownable, Destructible {
    LinniaUsers public usersContract;
    LinniaRecords public recordsContract;
    LinniaPermissions public permissionsContract;

    event LinniaUsersContractSet(address from, address to);
    event LinniaRecordsContractSet(address from, address to);
    event LinniaPermissionsContractSet(address from, address to);

    constructor() public { }

    function () public { }

    function setUsersContract(LinniaUsers _usersContract)
        onlyOwner
        external
        returns (bool)
    {
        address prev = address(usersContract);
        usersContract = _usersContract;
        emit LinniaUsersContractSet(prev, _usersContract);
        return true;
    }

    function setRecordsContract(LinniaRecords _recordsContract)
        onlyOwner
        external
        returns (bool)
    {
        address prev = address(recordsContract);
        recordsContract = _recordsContract;
        emit LinniaRecordsContractSet(prev, _recordsContract);
        return true;
    }

    function setPermissionsContract(LinniaPermissions _permissionsContract)
        onlyOwner
        external
        returns (bool)
    {
        address prev = address(permissionsContract);
        permissionsContract = _permissionsContract;
        emit LinniaPermissionsContractSet(prev, _permissionsContract);
        return true;
    }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract LinniaPermissions is Ownable, Pausable, Destructible {
    struct Permission {
        bool canAccess;
        // data path of the data, encrypted to the viewer
        string dataUri;
    }

    event LinniaAccessGranted(bytes32 indexed dataHash, address indexed owner,
        address indexed viewer, address sender
    );
    event LinniaAccessRevoked(bytes32 indexed dataHash, address indexed owner,
        address indexed viewer, address sender
    );
    event LinniaPermissionDelegateAdded(address indexed user, address indexed delegate);

    LinniaHub public hub;
    // dataHash => viewer => permission mapping
    mapping(bytes32 => mapping(address => Permission)) public permissions;
    // user => delegate => bool mapping
    mapping(address => mapping(address => bool)) public delegates;

    /* Modifiers */
    modifier onlyUser() {
        require(hub.usersContract().isUser(msg.sender));
        _;
    }

    modifier onlyRecordOwnerOf(bytes32 dataHash, address owner) {
        require(hub.recordsContract().recordOwnerOf(dataHash) == owner);
        _;
    }

    modifier onlyWhenSenderIsDelegate(address owner) {
        require(delegates[owner][msg.sender]);
        _;
    }

    /* Constructor */
    constructor(LinniaHub _hub) public {
        hub = _hub;
    }

    /* Fallback function */
    function () public { }

    /* External functions */

    /// Check if a viewer has access to a record
    /// @param dataHash the hash of the unencrypted data
    /// @param viewer the address being allowed to view the data

    function checkAccess(bytes32 dataHash, address viewer)
        view
        external
        returns (bool)
    {
        return permissions[dataHash][viewer].canAccess;
    }

    /// Add a delegate for a user&#39;s permissions
    /// @param delegate the address of the delegate being added by user
    function addDelegate(address delegate)
        onlyUser
        whenNotPaused
        external
        returns (bool)
    {
        require(delegate != address(0));
        require(delegate != msg.sender);
        delegates[msg.sender][delegate] = true;
        emit LinniaPermissionDelegateAdded(msg.sender, delegate);
        return true;
    }
    
    /// Give a viewer access to a linnia record
    /// Called by owner of the record.
    /// @param dataHash the data hash of the linnia record
    /// @param viewer the user being permissioned to view the data
    /// @param dataUri the path of the re-encrypted data
    function grantAccess(
        bytes32 dataHash, address viewer, string dataUri)
        onlyUser
        onlyRecordOwnerOf(dataHash, msg.sender)
        external
        returns (bool)
    {
        require(
            _grantAccess(dataHash, viewer, msg.sender, dataUri)
        );
        return true;
    }

    /// Give a viewer access to a linnia record
    /// Called by delegate to the owner of the record.
    /// @param dataHash the data hash of the linnia record
    /// @param viewer the user being permissioned to view the data
    /// @param owner the owner of the linnia record
    /// @param dataUri the path of the re-encrypted data
    function grantAccessbyDelegate(
        bytes32 dataHash, address viewer, address owner, string dataUri)
        onlyWhenSenderIsDelegate(owner)
        onlyRecordOwnerOf(dataHash, owner)
        external
        returns (bool)
    {
        require(
            _grantAccess(dataHash, viewer, owner, dataUri)
        );
        return true;
    }

    /// Revoke a viewer access to a linnia record
    /// Note that this does not necessarily remove the data from storage
    /// Called by owner of the record.
    /// @param dataHash the data hash of the linnia record
    /// @param viewer the user that has permission to view the data
    function revokeAccess(
        bytes32 dataHash, address viewer)
        onlyUser
        onlyRecordOwnerOf(dataHash, msg.sender)
        external
        returns (bool)
    {
        require(
            _revokeAccess(dataHash, viewer, msg.sender)
        );
        return true;
    }

    /// Revoke a viewer access to a linnia record
    /// Note that this does not necessarily remove the data from storage
    /// Called by delegate to the owner of the record.
    /// @param dataHash the data hash of the linnia record
    /// @param viewer the user that has permission to view the data
    /// @param owner the owner of the linnia record
    function revokeAccessbyDelegate(
        bytes32 dataHash, address viewer, address owner)
        onlyWhenSenderIsDelegate(owner)
        onlyRecordOwnerOf(dataHash, owner)
        external
        returns (bool)
    {
        require(_revokeAccess(dataHash, viewer, owner));
        return true;
    }

    /// Internal function to give a viewer access to a linnia record
    /// Called by external functions
    /// @param dataHash the data hash of the linnia record
    /// @param viewer the user being permissioned to view the data
    /// @param dataUri the data path of the re-encrypted data
    function _grantAccess(bytes32 dataHash, address viewer, address owner, string dataUri)
        whenNotPaused
        internal
        returns (bool)
    {
        // validate input
        require(owner != address(0));
        require(viewer != address(0));
        require(bytes(dataUri).length != 0);

        // TODO, Uncomment this to prevent grant access twice, It is commented for testing purposes
        // access must not have already been granted
        // require(!permissions[dataHash][viewer].canAccess);
        permissions[dataHash][viewer] = Permission({
            canAccess: true,
            dataUri: dataUri
            });
        emit LinniaAccessGranted(dataHash, owner, viewer, msg.sender);
        return true;
    }

    /// Internal function to revoke a viewer access to a linnia record
    /// Called by external functions
    /// Note that this does not necessarily remove the data from storage
    /// @param dataHash the data hash of the linnia record
    /// @param viewer the user that has permission to view the data
    /// @param owner the owner of the linnia record
    function _revokeAccess(bytes32 dataHash, address viewer, address owner)
        whenNotPaused
        internal
        returns (bool)
    {
        require(owner != address(0));
        // access must have already been grated
        require(permissions[dataHash][viewer].canAccess);
        permissions[dataHash][viewer] = Permission({
            canAccess: false,
            dataUri: ""
            });
        emit LinniaAccessRevoked(dataHash, owner, viewer, msg.sender);
        return true;
    }
}

contract LinniaRecords is Ownable, Pausable, Destructible {
    using SafeMath for uint;

    // Struct of a linnia record
    // A linnia record is identified by its data hash, which is
    // keccak256(data + optional nonce)
    struct Record {
        // owner of the record
        address owner;
        // hash of the plaintext metadata
        bytes32 metadataHash;
        // attestator signatures
        mapping (address => bool) sigs;
        // count of attestator sigs
        uint sigCount;
        // calculated iris score
        uint irisScore;
        // ipfs path of the encrypted data
        string dataUri;
        // timestamp of the block when the record is added
        uint timestamp;
        // non zero score returned from the specific IRIS provider oracles
        mapping (address => uint256)  irisProvidersReports;
    }

    event LinnniaUpdateRecordsIris(
        bytes32 indexed dataHash, address indexed irisProvidersAddress, uint256 val, address indexed sender)
    ;

    event LinniaRecordAdded(
        bytes32 indexed dataHash, address indexed owner, string metadata
    );

    event LinniaRecordSigAdded(
        bytes32 indexed dataHash, address indexed attestator, uint irisScore
    );

    event LinniaReward(bytes32 indexed dataHash, address indexed owner, uint256 value, address tokenContract);

    LinniaHub public hub;
    // all linnia records
    // dataHash => record mapping
    mapping(bytes32 => Record) public records;

    /* Modifiers */

    modifier onlyUser() {
        require(hub.usersContract().isUser(msg.sender) == true);
        _;
    }

    modifier hasProvenance(address user) {
        require(hub.usersContract().provenanceOf(user) > 0);
        _;
    }

    /* Constructor */
    constructor(LinniaHub _hub) public {
        hub = _hub;
    }

    /* Fallback function */
    function () public { }

    /* External functions */

    function addRecordByAdmin(
        bytes32 dataHash, address owner, address attestator,
        string metadata, string dataUri)
        onlyOwner
        whenNotPaused
        external
        returns (bool)
    {
        require(_addRecord(dataHash, owner, metadata, dataUri) == true);
        if (attestator != address(0)) {
            require(_addSig(dataHash, attestator));
        }
        return true;
    }

    /// @param dataHash the datahash of the record to be scored
    /// @param irisProvidersAddress address of the oracle contract
    function updateIris(bytes32 dataHash, address irisProvidersAddress)
        external
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        require(irisProvidersAddress != address(0));
        require(dataHash != 0);

        Record storage record = records[dataHash];
        // make sure the irisProviders is only called once
        require(record.irisProvidersReports[irisProvidersAddress] == 0);

        IrisScoreProviderI currOracle = IrisScoreProviderI(irisProvidersAddress);
        uint256 val = currOracle.report(dataHash);
        // zero and less values are reverted
        require(val > 0);

        record.irisScore.add(val);
        // keep a record of iris score breakdown
        record.irisProvidersReports[irisProvidersAddress] = val;
        emit LinnniaUpdateRecordsIris(dataHash, irisProvidersAddress, val, msg.sender);
        return val;
    }

    /* Public functions */

    /// Add a record by user without any provider&#39;s signatures.
    /// @param dataHash the hash of the data
    /// @param metadata plaintext metadata for the record
    /// @param dataUri the ipfs path of the encrypted data
    function addRecord(
        bytes32 dataHash, string metadata, string dataUri)
        onlyUser
        whenNotPaused
        public
        returns (bool)
    {
        require(
            _addRecord(dataHash, msg.sender, metadata, dataUri) == true
        );
        return true;
    }

    /// Add a record by user without any provider&#39;s signatures and get a reward.
    ///
    /// @param dataHash the hash of the data
    /// @param metadata plaintext metadata for the record
    /// @param dataUri the data uri path of the encrypted data
    /// @param token the ERC20 token address for the rewarding token
    function addRecordwithReward (
        bytes32 dataHash, string metadata, string dataUri, address token)
        onlyUser
        whenNotPaused
        public
        returns  (bool)
    {
        // the amount of tokens to be transferred
        uint256 reward = 1 finney;
        require (token != address (0));
        require (token != address (this));
        ERC20 tokenInstance = ERC20 (token);
        require (
            _addRecord (dataHash, msg.sender, metadata, dataUri) == true
        );
        // tokens are provided by the contracts balance
        require(tokenInstance.transfer (msg.sender, reward));
        emit LinniaReward (dataHash, msg.sender, reward, token);
        return true;
    }

    /// Add a record by a data provider.
    /// @param dataHash the hash of the data
    /// @param owner owner of the record
    /// @param metadata plaintext metadata for the record
    /// @param dataUri the ipfs path of the encrypted data
    function addRecordByProvider(
        bytes32 dataHash, address owner, string metadata, string dataUri)
        onlyUser
        hasProvenance(msg.sender)
        whenNotPaused
        public
        returns (bool)
    {
        // add the file first
        require(_addRecord(dataHash, owner, metadata, dataUri) == true);
        // add provider&#39;s sig to the file
        require(_addSig(dataHash, msg.sender));
        return true;
    }

    /// Add a provider&#39;s signature to a linnia record,
    /// i.e. adding an attestation
    /// This function is only callable by a provider
    /// @param dataHash the data hash of the linnia record
    function addSigByProvider(bytes32 dataHash)
        hasProvenance(msg.sender)
        whenNotPaused
        public
        returns (bool)
    {
        require(_addSig(dataHash, msg.sender));
        return true;
    }

    /// Add a provider&#39;s signature to a linnia record
    /// i.e. adding an attestation
    /// This function can be called by anyone. As long as the signatures are
    /// indeed from a provider, the sig will be added to the record.
    /// The signature should cover the root hash, which is
    /// hash(hash(data), hash(metadata))
    /// @param dataHash the data hash of a linnia record
    /// @param r signature: R
    /// @param s signature: S
    /// @param v signature: V
    function addSig(bytes32 dataHash, bytes32 r, bytes32 s, uint8 v)
        public
        whenNotPaused
        returns (bool)
    {
        // find the root hash of the record
        bytes32 rootHash = rootHashOf(dataHash);
        // recover the provider&#39;s address from signature
        address provider = recover(rootHash, r, s, v);
        // add sig
        require(_addSig(dataHash, provider));
        return true;
    }

    function recover(bytes32 message, bytes32 r, bytes32 s, uint8 v)
        public pure returns (address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
        return ecrecover(prefixedHash, v, r, s);
    }

    function recordOwnerOf(bytes32 dataHash)
        public view returns (address)
    {
        return records[dataHash].owner;
    }

    function rootHashOf(bytes32 dataHash)
        public view returns (bytes32)
    {
        return keccak256(abi.encodePacked(dataHash, records[dataHash].metadataHash));
    }

    function sigExists(bytes32 dataHash, address provider)
        public view returns (bool)
    {
        return records[dataHash].sigs[provider];
    }

    /* Internal functions */

    function _addRecord(
        bytes32 dataHash, address owner, string metadata, string dataUri)
        internal
        returns (bool)
    {
        // validate input
        require(dataHash != 0);
        require(bytes(dataUri).length != 0);
        bytes32 metadataHash = keccak256(abi.encodePacked(metadata));

        // the file must be new
        require(records[dataHash].timestamp == 0);
        // verify owner
        require(hub.usersContract().isUser(owner) == true);
        // add record
        records[dataHash] = Record({
            owner: owner,
            metadataHash: metadataHash,
            sigCount: 0,
            irisScore: 0,
            dataUri: dataUri,
            // solium-disable-next-line security/no-block-members
            timestamp: block.timestamp
            });
        // emit event
        emit LinniaRecordAdded(dataHash, owner, metadata);
        return true;
    }

    function _addSig(bytes32 dataHash, address provider)
        hasProvenance(provider)
        internal
        returns (bool)
    {
        Record storage record = records[dataHash];
        // the file must exist
        require(record.timestamp != 0);
        // the provider must not have signed the file already
        require(!record.sigs[provider]);
        uint provenanceScore = hub.usersContract().provenanceOf(provider);
        // add signature
        record.sigCount = record.sigCount.add(1);
        record.sigs[provider] = true;
        // update iris score
        record.irisScore = record.irisScore.add(provenanceScore);
        // emit event
        emit LinniaRecordSigAdded(dataHash, provider, record.irisScore);
        return true;
    }
}

contract LinniaUsers is Ownable, Pausable, Destructible {
    struct User {
        bool exists;
        uint registerBlocktime;
        uint provenance;
    }

    event LinniaUserRegistered(address indexed user);
    event LinniaProvenanceChanged(address indexed user, uint provenance);
    event LinniaWhitelistScoreAdded(address indexed whitelist);

    LinniaHub public hub;
    mapping(address => User) public users;

    constructor(LinniaHub _hub) public {
        hub = _hub;
    }

    /* Fallback function */
    function () public { }

    /* External functions */

    // register allows any user to self register on Linnia
    function register()
        whenNotPaused
        external
        returns (bool)
    {
        require(!isUser(msg.sender));
        users[msg.sender] = User({
            exists: true,
            registerBlocktime: block.number,
            provenance: 0
        });
        emit LinniaUserRegistered(msg.sender);
        return true;
    }

     // setExpertScore allows admin to set the expert score of a user from a trusted third party
    function setExpertScore(LinniaWhitelistI whitelist, address user)
        onlyOwner
        external
        returns (bool)
    {
        uint score = whitelist.expertScoreOf(user);
        setProvenance(user, score);
        emit LinniaWhitelistScoreAdded(whitelist);
        return true;
    }

    /* Public functions */

     // setProvenance allows admin to set the provenance of a user
    function setProvenance(address user, uint provenance)
        onlyOwner
        public
        returns (bool)
    {
        require(isUser(user));
        users[user].provenance = provenance;
        emit LinniaProvenanceChanged(user, provenance);
        return true;
    }

    function isUser(address user)
        public
        view
        returns (bool)
    {
        return users[user].exists;
    }

    function provenanceOf(address user)
        public
        view
        returns (uint)
    {
        if (users[user].exists) {
            return users[user].provenance;
        } else {
            return 0;
        }
    }
}