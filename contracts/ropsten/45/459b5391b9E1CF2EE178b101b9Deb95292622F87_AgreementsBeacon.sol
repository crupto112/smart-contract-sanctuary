// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.1;

import "./agreements-beacon-interface.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AgreementsBeacon is
    Context,
    AccessControlEnumerable,
    IAgreementsBeacon
{
    using Address for address;
    using Strings for uint256;

    mapping(address => mapping(uint256 => Beacon)) internal beacons;

    bytes32 private constant EVENT_NAMESPACE = "monax";
    bytes32 private constant EVENT_NAME_BEACON_STATE_CHANGE =
        "request:beacon-status-change";
    bytes32 private constant EVENT_NAME_REQUEST_CREATE_AGREEMENT =
        "request:create-agreement";
    bytes32 private constant EVENT_NAME_REPORT_AGREEMENT_STATUS =
        "report:agreement-status";

    bytes32 public constant MGR_ROLE = keccak256("MGR_ROLE");
    bytes32 public constant RPTR_ROLE = keccak256("RPTR_ROLE");

    uint256 public constant AGREEMENT_BEACON_PRICE = 1000; // TODO

    uint256 internal _requestIndex;
    uint256 internal _currentEventIndex;
    string internal _baseURI;

    modifier mgrsOnly() {
        require(hasRole(MGR_ROLE, _msgSender()), "must have manager role");
        _;
    }

    modifier reportersOnly() {
        require(hasRole(RPTR_ROLE, _msgSender()), "must have reporter role");
        _;
    }

    modifier requireCharge() {
        require(
            msg.value >= AGREEMENT_BEACON_PRICE,
            "Insufficient funds for operation"
        );
        _;
    }

    modifier isBeaconActivated(address tokenContractAddress, uint256 tokenId) {
        require(
            beacons[tokenContractAddress][tokenId].activated,
            "Beacon not activated"
        );
        _;
    }

    modifier addEvent(uint256 eventCount) {
        _;
        _currentEventIndex += eventCount;
    }

    modifier addRequestIndex() {
        _;
        _requestIndex += 1;
    }

    constructor() {
        _requestIndex = 1;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MGR_ROLE, _msgSender());
        _setupRole(RPTR_ROLE, _msgSender());
        _baseURI = string(
            abi.encodePacked(
                "https://agreements.zone/tokens/ethereum/",
                block.chainid.toString(),
                "/{tokenContractAddress}/{id}"
            )
        );
    }

    function requestCreateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig
    ) external payable virtual override requireCharge() {
        require(
            beacons[tokenContractAddress][tokenId].creator == address(0),
            "Request limit reached"
        );
        beacons[tokenContractAddress][tokenId].creator = _msgSender();
        beacons[tokenContractAddress][tokenId].templateId = templateId;
        beacons[tokenContractAddress][tokenId].templateConfig = templateConfig;
        beacons[tokenContractAddress][tokenId].activated = true;
        _emitBeaconStateChange(
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            true
        );
    }

    function requestUpdateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig,
        bool activated
    ) external payable virtual override requireCharge() {
        require(
            beacons[tokenContractAddress][tokenId].creator == _msgSender(),
            "You do not own me"
        );
        beacons[tokenContractAddress][tokenId].templateId = templateId;
        beacons[tokenContractAddress][tokenId].templateConfig = templateConfig;
        beacons[tokenContractAddress][tokenId].activated = activated;
        _emitBeaconStateChange(
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            activated
        );
    }

    function requestCreateAgreement(
        address tokenContractAddress,
        uint256 tokenId,
        address[] memory accepters
    )
        external
        payable
        virtual
        override
        requireCharge()
        isBeaconActivated(tokenContractAddress, tokenId)
        addRequestIndex()
    {
        for (uint256 i = 0; i < accepters.length; i++) {
            address accepter = accepters[i];
            if (
                beacons[tokenContractAddress][tokenId].agreements[accepter]
                    .requestIndex != 0
            ) {
                continue;
            }
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .creator = beacons[tokenContractAddress][tokenId].creator;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .accepter = accepter;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .state = LegalState.FORMULATED;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex = _requestIndex;
            _emitCreateAgreementRequest(
                tokenContractAddress,
                tokenId,
                accepter
            );
        }
    }

    function reportAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter,
        address agreement,
        LegalState state,
        string memory errorCode
    ) external virtual override reportersOnly() {
        if (
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement == address(0)
        ) {
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement = agreement;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .state = state;
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .errorCode = errorCode;
        } else {
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .state = state;
        }
        beacons[tokenContractAddress][tokenId].agreements[accepter]
            .currentBlockHeight = block.number;
        beacons[tokenContractAddress][tokenId].agreements[accepter]
            .currentEventIndex = _currentEventIndex;
        _emitAgreementStatus(tokenContractAddress, tokenId, accepter);
    }

    function drain(address payable _destination) external virtual mgrsOnly() {
        _destination.transfer(address(this).balance);
    }

    function getBeaconURI(address tokenContractAddress, uint256 tokenId)
        external
        view
        virtual
        override
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (string memory)
    {
        return _baseURI;
    }

    function getBeaconCreator(address tokenContractAddress, uint256 tokenId)
        external
        view
        virtual
        override
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (address creator)
    {
        return beacons[tokenContractAddress][tokenId].creator;
    }

    function getAgreementId(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    )
        external
        view
        virtual
        override
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (address agreement)
    {
        return
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement;
    }

    function getAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    )
        external
        view
        virtual
        override
        isBeaconActivated(tokenContractAddress, tokenId)
        returns (LegalState state)
    {
        return
            beacons[tokenContractAddress][tokenId].agreements[accepter].state;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IAgreementsBeacon).interfaceId;
    }

    function _emitBeaconStateChange(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig,
        bool activated
    ) internal addEvent(1) {
        emit LogBeaconStatusChange(
            EVENT_NAMESPACE,
            EVENT_NAME_BEACON_STATE_CHANGE,
            _msgSender(),
            tx.origin, // solhint-disable-line avoid-tx-origin
            tokenContractAddress,
            tokenId,
            templateId,
            templateConfig,
            activated,
            block.number,
            _currentEventIndex
        );
    }

    function _emitCreateAgreementRequest(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) internal addEvent(1) {
        emit LogRequestCreateAgreement(
            EVENT_NAMESPACE,
            EVENT_NAME_REQUEST_CREATE_AGREEMENT,
            _msgSender(),
            tx.origin, // solhint-disable-line avoid-tx-origin
            tokenContractAddress,
            tokenId,
            accepter,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex,
            block.number,
            _currentEventIndex
        );
    }

    function _emitAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) internal addEvent(1) {
        emit LogAgreementStatus(
            EVENT_NAMESPACE,
            EVENT_NAME_REPORT_AGREEMENT_STATUS,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .agreement,
            beacons[tokenContractAddress][tokenId].agreements[accepter].state,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .errorCode,
            beacons[tokenContractAddress][tokenId].agreements[accepter]
                .requestIndex,
            block.number,
            _currentEventIndex
        );
    }
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IAgreementsBeacon is IERC165 {
    struct Beacon {
        address creator;
        bool activated;
        bytes32 templateId;
        string templateConfig;
        mapping(address => Agreement) agreements;
    }

    struct Agreement {
        address creator;
        address accepter;
        address agreement;
        LegalState state;
        string errorCode;
        uint256 requestIndex;
        uint256 currentBlockHeight;
        uint256 currentEventIndex;
    }
    /**
     * @dev State change enum for an agreement
     */
    enum LegalState {
        DRAFT,
        FORMULATED,
        EXECUTED,
        FULFILLED,
        DEFAULT,
        CANCELED,
        UNDEFINED,
        REDACTED
    }

    /**
     * @dev Emitted when `creator` (potentially via a `relayer`) modifies the state
     * of a beacon for a `tokenContractAddress` and `tokenId` by creating or updating
     * the `templateId` or `templateConfig` that are used to determine the agreement
     * for the token. The `creator` may also turn the beacon on or off via the
     * `activated` field.
     */
    event LogBeaconStatusChange(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address creator,
        address relayer,
        address indexed tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string templateConfig,
        bool activated,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    /**
     * @dev Emitted when `creator` (potentially via a `relayer`) of an agreement request
     * asks the beacon to establish a new digital agreement for a given `tokenContractAddress`
     * and `tokenId` combination. The entity accepting the contract offered by the
     * beacon creator will be the `accepter` which may differ from the `creator` or `relayer`.
     *
     * To allow correlation between and across requests, each event will have an embedded
     * `requestIndex` for every request.
     */
    event LogRequestCreateAgreement(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address creator,
        address relayer,
        address indexed tokenContractAddress,
        uint256 tokenId,
        address accepter,
        uint256 requestIndex,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    /**
     * @dev Emitted when the beacon has determined that there has been a change in `state`
     * for the digital `agreement`. Can also log and `errorCode` during the agreement creation
     * process. Finally a `requestIndex` is emitted which allows for correlation with {LogRequestCreateAgreement}
     * events.
     */
    event LogAgreementStatus(
        bytes32 indexed eventNamespace,
        bytes32 indexed eventCategory,
        address agreement,
        LegalState state,
        string errorCode,
        uint256 requestIndex,
        uint256 currentBlockHeight,
        uint256 currentEventIndex
    );

    /**
     * @dev Handles the request to create an agreement beacon which will connect a specific token
     * to a set of specific digital agreements that have been agreed to by counterparties.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param templateId The ID of the template that will be used to formulate the agreements (convert
     * the UUID to bytes32 string)
     * @param templateConfig The URL location (preferrable encrypted IPFS hash or Hoard grant) to the
     * JSON encoded parameters to be used with the template ID
     *
     * Emits a {LogBeaconStatusChange} event.
     *
     * Requirements:
     * - minter of the token must not have previously requested beacon activation (note the AgreementsBeacon
     * is purposefully ignorant of who initially owns a particular token)
     * - the {AGREEMENT_BEACON_PRICE} must accompany any calls
     */
    function requestCreateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig
    ) external payable;

    /**
     * @dev Handles the request to update an agreement beacon which will connect a specific token
     * to a set of specific digital agreements that have been agreed to by counterparties.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param templateId The ID of the template that will be used to formulate the agreements (convert the
     * UUID to bytes32 string)
     * @param templateConfig The URL location (preferrable encrypted IPFS hash or Hoard grant) to the JSON
     * encoded parameters to be used with the template ID
     * @param activated Whether the beacon should be turned on or off
     *
     * Emits a {LogBeaconStatusChange} event.
     *
     * Requirements:
     * - requester must have the same address as that which initially requested activation
     * - the {AGREEMENT_BEACON_PRICE} must accompany any calls
     */
    function requestUpdateBeacon(
        address tokenContractAddress,
        uint256 tokenId,
        bytes32 templateId,
        string memory templateConfig,
        bool activated
    ) external payable;

    /**
     * @dev Handles the request to create an agreement based the template established by a beacon creator.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param accepters The addresses of those accepting the terms of the token as established by the creator
     *
     * Emits {LogRequestCreateAgreement} events (one per accepting party).
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     * - the {AGREEMENT_BEACON_PRICE} must accompany any calls
     */
    function requestCreateAgreement(
        address tokenContractAddress,
        uint256 tokenId,
        address[] memory accepters
    ) external payable;

    /**
     * @dev Handles the logging of state changes to the agreements between the parties.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param accepter The address of those accepting the terms of the token as established by the creator
     * @param agreement The address (within the agreement zone) of the agreement between the creator and
     * the accepter
     * @param state The {LegalState} of the agreement
     * @param errorCode Any error code exhibited by the beacon creating the agreement within the agreements
     * zone (generally follows HTTP error codes)
     *
     * Emits a {LogAgreementStatus} event.
     *
     * Requirements:
     * - only addresses which have the correct roles may call this function
     */
    function reportAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter,
        address agreement,
        LegalState state,
        string memory errorCode
    ) external;

    /**
     * @dev Retrieves the legalURL for the agreement beacon.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     *
     */
    function getBeaconURI(address tokenContractAddress, uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @dev Retrieves the address of the creator of the agreement beacon.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     *
     */
    function getBeaconCreator(address tokenContractAddress, uint256 tokenId)
        external
        view
        returns (address creator);

    /**
     * @dev Retrieves the address of the creator of the agreement beacon.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param accepter The address of those accepting the terms of the token as established by the creator
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     *
     */
    function getAgreementId(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) external view returns (address agreement);

    /**
     * @dev Retrieves the {LegalState} of the agreement between the creator and accepter known to the]
     * agreement beacon.
     *
     * @param tokenContractAddress The token contract owning the token to be integrated via the beacon
     * @param tokenId The ID of the token to be integrated via the beacon
     * @param accepter The address of those accepting the terms of the token as established by the creator
     *
     * Requirements:
     * - the beacon must be activated by the creator of the beacon
     *
     */
    function getAgreementStatus(
        address tokenContractAddress,
        uint256 tokenId,
        address accepter
    ) external view returns (LegalState state);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}