/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
library AddrArrayLib {
    using AddrArrayLib for Addresses;
    struct Addresses {
        address[]  _items;
    }
    function pushAddress(Addresses storage self, address element, bool allowDup) internal {
        if( allowDup ){
            self._items.push(element);
        }else if (!exists(self, element)) {
            self._items.push(element);
        }
    }
    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }
    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }
    function size(Addresses storage self) internal view returns (uint256) {
        return self._items.length;
    }
    function exists(Addresses storage self, address element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }
    function getAllAddresses(Addresses storage self) internal view returns(address[] memory) {
        return self._items;
    }
}
