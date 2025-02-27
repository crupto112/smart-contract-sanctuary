/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity >=0.6.2 <0.8.0;

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



pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



pragma solidity >=0.6.0 <0.8.0;

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



pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}



pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: contracts/interface/INFTReward.sol

pragma solidity ^0.6.12;

interface INFTReward {
    function addReward(uint256 _reward) external;
}

// File: contracts/interface/ITree.sol

pragma solidity >=0.6.0 <0.8.0;

interface ITree {
    function getNFT(uint256 _tokenId) external view returns (uint256 level, uint256 blockNumber, uint256 createTime);
}

// File: contracts/interface/IInviteRelation.sol

pragma solidity ^0.6.12;

interface IInviteRelation {
    function getSuperUser(address _addr) external view returns (address);
    function sendReward(address _to, uint256 _amount) external;
}

// File: contracts/mining/NFTMining.sol

pragma solidity ^0.6.12;








contract NFTMining is Ownable, IERC721Receiver{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     // 用户抵押的 LP 数量
        uint256 rewardDebt; // 用户奖励的债务
        uint256 lastBlock; // 用户抵押 提现 领取后更新的操作
        uint256 nftId; // nftId

        // 用户应得挖矿奖励计算:
        //
        //   pending reward = (addition * user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // 用户抵押，提现时进行的操作:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        //   5. 用户的生产力加成数值改变位置
        // 抵押代币
        // 提现代币
        // 移除nft
        // 更换nft
    }

    // 池子的信息
    struct PoolInfo {
        IERC20 lpToken;           // LP 地址
        uint256 allocPoint;       // 池子的权重
        uint256 lastRewardBlock;  // 最新的奖励区块
        uint256 accTokenPerShare; // 根据区块计算平均每个块挖到的 token
        uint256 totalDeposit;     // 有效抵押数
        uint256 lpSupply;         // 抵押的数量
        uint256 additionSupply;   // 加成生产力
    }

    // 奖励代币
    IERC20 public token;
    // 每个块产的奖励代币
    uint256 public tokenPerBlock;
    // 所有池子的总权重
    uint256 public totalAllocPoint = 0;
    // 挖矿开始区块
    uint256 public startBlock;
    // 挖矿结束区块
    uint256 public endBlock;
    // 提现手续费
    uint256 public withdrawFeeRate = 10;
    // 3天后提现手续费
    uint256 public withdrawFeeRate2 = 5;
    // 提现区块间隔 5760 * 3 3天按照15秒一个块统计
    uint256 public withdrawBlockInterval = 17280;
    // 提取收益手续费
    uint256 public harvestFeeRate = 10;
    // 限制
    uint256 public limitLevel = 8;
    // seed 奖励百分比
    uint256 public seedFormatRate = 1000;
    uint256 public seedRate1 = 50;
    uint256 public seedRate2 = 20;
    uint256 public seedRate3 = 10;
    uint256 public seedRate4 = 5;

    // 储蓄地址
    address public feeAddr;
    // 分红合约地址
    address public nftRewardContract;
    // nft token 地址
    address public nftToken;
    // 邀请合约地址
    address public inviteContract;
    // 池子数组信息
    PoolInfo[] public poolInfo;
    // 用户信息映射
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => uint256) public levelAddition;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    // 构造函数
    // token: 奖励代币
    // startBlock: 挖矿起始区块
    // tokenPerBlock: 每个区块产矿数
    constructor(
        IERC20 _token,
        uint256 _startBlock,
        uint256 _initTokenBase,
        uint256 _endBlock,
        address _feeAddr
    ) public {
        token = _token;
        tokenPerBlock = _initTokenBase;
        startBlock = _startBlock;
        endBlock = _endBlock;
        feeAddr = _feeAddr;
    }

    // 接受nft 避免没有实现转账功能
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // 设置结束区块
    function setEndBlock(uint256 _endBlock) public onlyOwner {
        endBlock = _endBlock;
    }

    // 设置开始区块
    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function setSeedRate(
        uint256 _seed1,
        uint256 _seed2,
        uint256 _seed3,
        uint256 _seed4
    ) public onlyOwner {
        seedRate1 = _seed1;
        seedRate2 = _seed2;
        seedRate3 = _seed3;
        seedRate4 = _seed4;
    }

    function setNFTRewardContract(address _nftRewardContract) public onlyOwner {
        require(_nftRewardContract != address(0), "address can not be zero");
        nftRewardContract = _nftRewardContract;
    }

    function setInviteContract(address _inviteContact) public onlyOwner {
        require(_inviteContact != address(0));
        inviteContract = _inviteContact;
    }

    function setNFTToken(address _nftToken) public onlyOwner {
        require(_nftToken != address(0), "address can not be zero");
        nftToken = _nftToken;
    }

    function setLimitLevel(uint256 _level) public onlyOwner {
        limitLevel = _level;
    }

    // 初始化等级加成值
    function initLevelAddition() public onlyOwner {
        setLevelAddition(1, 5);
        setLevelAddition(2, 10);
        setLevelAddition(3, 15);
        setLevelAddition(4, 20);
        setLevelAddition(5, 30);
        setLevelAddition(6, 40);
        setLevelAddition(7, 50);
    }

    // 设置等级加成属性
    function setLevelAddition(uint256 _level, uint256 _addition) public onlyOwner {
        require(_level > 0, "addition level need > 0");
        levelAddition[_level] = _addition;
    }

    // 设置领取收益手续费比例 10% 设置 10 即可
    function setHarvestFeeRate(uint256 _feeRate) public onlyOwner {
        harvestFeeRate = _feeRate;
    }

    // 设置提取令牌手续费比例 2% 设置 2 即可
    function setWithdrawFeeRate(uint256 _feeRate) public onlyOwner {
        withdrawFeeRate = _feeRate;
    }

    // 设置提取令牌手续费比例 2% 设置 2 即可
    function setWithdrawFeeRate2(uint256 _feeRate) public onlyOwner {
        withdrawFeeRate2 = _feeRate;
    }

    // 设置提现收取手续费的周期间隔
    function setWithdrawBlockInterval(uint256 _withdrawBlockInterval) public onlyOwner {
        withdrawBlockInterval = _withdrawBlockInterval;
    }

    // 流动池数量
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // 新增 LP 池子
    // 不要添加相同 LP token 的池子，会引起计算混乱
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accTokenPerShare : 0,
            totalDeposit : 0,
            lpSupply : 0,
            additionSupply : 0
            }));
    }

    // 更新池子的权重
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // 返回区块奖励因数
    function getMultiplier(uint256 _from, uint256 _to, uint baseRatio) public pure returns (uint256) {
        return _to.sub(_from).mul(baseRatio);
    }

    // 前端渲染挖矿奖励数值
    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint baseRatio = 1e12;
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number > endBlock ? endBlock : block.number, baseRatio);
            uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint).div(baseRatio);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(pool.additionSupply));
        }
        // 获取nft 加成属性
        return getAdditionByTokenId(user.nftId).add(100).mul(user.amount).mul(accTokenPerShare).div(100).div(1e12).sub(user.rewardDebt);
    }

    // 强制更新池子信息
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // 更新池子信息
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint baseRatio = 1e12;
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number > endBlock ? endBlock : block.number, baseRatio);
        uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint).div(baseRatio);

        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e12).div(pool.additionSupply));
        pool.lastRewardBlock = block.number > endBlock ? endBlock : block.number;
    }

    function checkNFT(uint256 _nftId) internal view {
        require(IERC721(nftToken).ownerOf(_nftId) == msg.sender, "you are not owner of this nft");
        (uint256 level,,) = ITree(nftToken).getNFT(_nftId);
        require(level > 0 && level < limitLevel, "no permission nft");
    }

    // 抵押 LP token 当 amount 为 0 时、领取挖矿奖励
    function depositNft(uint256 _pid, uint256 _nftId) public {
        if (_nftId != 0) {
            checkNFT(_nftId);
        }
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        uint256 pending = getAdditionByTokenId(user.nftId).add(100).mul(user.amount).mul(pool.accTokenPerShare).div(100).div(1e12).sub(user.rewardDebt);
        // 发送seed 奖励
        sendSeed(pending);
        uint256 harvestFee = pending.mul(harvestFeeRate).div(100);
        uint256 awardFee = harvestFee.div(6);
        // 1/6 转入分红池
        safeTokenTransfer(nftRewardContract, awardFee);
        // 一半转入储蓄地址
        safeTokenTransfer(feeAddr, harvestFee.sub(awardFee));
        // 扣除手续费后获得 pending 值
        pending = pending.sub(harvestFee);
        safeTokenTransfer(msg.sender, pending);

        // 生产力变更
        pool.additionSupply = pool.additionSupply.sub(user.amount.mul(getAdditionByTokenId(user.nftId).add(100)).div(100));
        pool.additionSupply = pool.additionSupply.add(user.amount.mul(getAdditionByTokenId(_nftId).add(100)).div(100));
        // 移除nft
        if (_nftId == 0) {
            require(user.nftId > 0, "user's nft is not exist");
            // 转移nft 回用户
            IERC721(nftToken).safeTransferFrom(address(this), msg.sender, user.nftId);
        } else {
            // 更换nft
            if (user.nftId != 0) {
                // 合约上的 nft 转到用户
                IERC721(nftToken).safeTransferFrom(address(this), msg.sender, user.nftId);
            }
            // 转移用户 nft 到合约
            IERC721(nftToken).safeTransferFrom(msg.sender, address(this), _nftId);
        }

        user.nftId = _nftId;
        // 债务更新
        user.rewardDebt = getAdditionByTokenId(user.nftId).add(100).mul(user.amount).mul(pool.accTokenPerShare).div(100).div(1e12);
    }

    // 抵押 LP token 当 amount 为 0 时、领取挖矿奖励
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 如果是抵押令牌
        if (_amount > 0) {
            // 如果是初次新增抵押，则有效抵押数量 +1
            if (user.amount == 0) {
                pool.totalDeposit = pool.totalDeposit.add(1);
            }
        }
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = getAdditionByTokenId(user.nftId).add(100).mul(user.amount).mul(pool.accTokenPerShare).div(100).div(1e12).sub(user.rewardDebt);
            // 发送seed 奖励
            sendSeed(pending);
            uint256 fee = pending.mul(harvestFeeRate).div(100);
            uint256 awardFee = fee.div(6);
            // 一半转入分红池
            safeTokenTransfer(nftRewardContract, awardFee);
            // 一半转入储蓄地址
            safeTokenTransfer(feeAddr, fee.sub(awardFee));
            // 扣除手续费后获得 pending 值
            pending = pending.sub(fee);
            safeTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            // 增加矿池 抵押令牌和挖出来的矿是同一种的情况 不然 uint256 lpSupply = pool.lpToken.balanceOf(address(this)); 这个在updatePool pendingToken 时 会混乱
            pool.lpSupply = pool.lpSupply.add(_amount);
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            // 生产力增加
            pool.additionSupply = pool.additionSupply.add(_amount.mul(getAdditionByTokenId(user.nftId).add(100)).div(100));
            // 更新最新抵押区块数
            user.lastBlock = block.number;
        }
        user.amount = user.amount.add(_amount);
        // 债务增加
        user.rewardDebt = getAdditionByTokenId(user.nftId).add(100).mul(user.amount).mul(pool.accTokenPerShare).div(100).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // 获取加成生产力
    function getAdditionByTokenId(uint256 _tokenId) public view returns (uint256){
        if (_tokenId == 0) {
            return 0;
        }
        (uint256 level,,) = ITree(nftToken).getNFT(_tokenId);
        return levelAddition[level];
    }

    function sendSeed(uint256 pending) internal {
        if (pending == 0) {
            return;
        }
        // 给上级15代人数加1
        address parent = IInviteRelation(inviteContract).getSuperUser(msg.sender);
        uint256 seed;
        uint256 seedRate;
        for (uint256 i = 0; i < 15; i++) {
            if (parent == address(0) || parent == inviteContract) {
                break;
            }
            if (!ifStaking(parent)) {
                parent = IInviteRelation(inviteContract).getSuperUser(parent);
                continue;
            }
            if (i == 0) {
                seedRate = seedRate1;
            }
            if (i > 0 && i < 5) {
                seedRate = seedRate2;
            }
            if (i >= 5 && i < 10) {
                seedRate = seedRate3;
            }
            if (i >= 10 && i < 15) {
                seedRate = seedRate4;
            }
            seed = pending.mul(seedRate).div(seedFormatRate);
            if (seed > 0) {
                IInviteRelation(inviteContract).sendReward(parent, seed);
            }
            parent = IInviteRelation(inviteContract).getSuperUser(parent);
        }
    }

    // 是否已经抵押
    function ifStaking(address userAddr) public view returns (bool) {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            uint256 amount = userInfo[i][userAddr].amount;
            if (amount > 0) {
                return true;
            }
        }
        return false;
    }

    // 提取 LP token
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = getAdditionByTokenId(user.nftId).add(100).mul(user.amount).mul(pool.accTokenPerShare).div(100).div(1e12).sub(user.rewardDebt);
        // 发送seed 奖励
        sendSeed(pending);
        uint256 harvestFee = pending.mul(harvestFeeRate).div(100);
        uint256 awardFee = harvestFee.div(6);
        // 一半转入分红池
        safeTokenTransfer(nftRewardContract, awardFee);
        // 一半转入储蓄地址
        safeTokenTransfer(feeAddr, harvestFee.sub(awardFee));
        // 扣除手续费后获得 pending 值
        pending = pending.sub(harvestFee);
        safeTokenTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);

        if (user.amount == 0) {
            pool.totalDeposit = pool.totalDeposit.sub(1);
        }
        user.rewardDebt = getAdditionByTokenId(user.nftId).add(100).mul(user.amount).mul(pool.accTokenPerShare).div(100).div(1e12);
        uint256 fund = _amount;
        // 移除lpSupply
        pool.lpSupply = pool.lpSupply.sub(_amount);
        // 生产力扣除
        pool.additionSupply = pool.additionSupply.sub(_amount.mul(getAdditionByTokenId(user.nftId).add(100)).div(100));
//        uint256 fee;
//        // 三天内提取 扣除本金 作为手续费
//        if (user.lastBlock.add(withdrawBlockInterval) > block.number) {
//            fee = fund.mul(withdrawFeeRate).div(100);
//        } else {
//            fee = fund.mul(withdrawFeeRate2).div(100);
//        }
//        // 发送手续费 到手续费地址
//        safeTransferByToken(pool.lpToken, token, feeAddr, fee);
//
//        // 领取扣除手续费后的收益 到msg.sender
//        fund = fund.sub(fee);
        safeTransferByToken(pool.lpToken, token, address(msg.sender), fund);
        // 更新最新抵押区块数
        user.lastBlock = block.number;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // 收取手续费
    function safeTransferByToken(IERC20 _lpToken, IERC20 _token, address _to, uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }
        if (_lpToken == _token) {
            safeTokenTransfer(_to, _amount);
        } else {
            _lpToken.safeTransfer(_to, _amount);
        }
    }

    // 不要奖励，直接提取 LP token
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 fund = user.amount;
//        uint256 fee;
//        if (user.lastBlock.add(withdrawBlockInterval) > block.number) {
//            fee = fund.mul(withdrawFeeRate).div(100);
//        } else {
//            fee = fund.mul(withdrawFeeRate2).div(100);
//        }
//        // 发送手续费 到手续费地址
//        safeTransferByToken(pool.lpToken, token, feeAddr, fee);
//        // 领取扣除手续费后的收益 到msg.sender
//        fund = fund.sub(fee);
        safeTransferByToken(pool.lpToken, token, address(msg.sender), fund);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    // 从合约发送奖励代币 如果合约账户代币不足，则直接 return
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount == 0 || tokenBal == 0) {
            return;
        }
        if (_amount > tokenBal) {
            token.safeTransfer(_to, tokenBal);
            // 如果是分红进入分红池的是分红池，则给分红池增加相应的数值
            if (_to == nftRewardContract) {
                INFTReward(nftRewardContract).addReward(tokenBal);
            }
        } else {
            token.safeTransfer(_to, _amount);
            if (_to == nftRewardContract) {
                INFTReward(nftRewardContract).addReward(_amount);
            }
        }
    }

    // 转移合约上的代币到指定地址，可由部署者操作
    function forceTransfer(address _addr, uint256 _amount) public onlyOwner {
        require(_addr != address(0), "address can not be 0");
        safeTokenTransfer(_addr, _amount);
    }

    // 获取总抵押人数
    function getTotalDeposit(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.totalDeposit;
    }

}