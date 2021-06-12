/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library Uint256ArrayLib {
    using Uint256ArrayLib for Values;

    struct Values {
        uint256[]  _items;
    }

    /**
     * @notice push an uint256 to the array
     * @dev if the uint256 already exists, it will not be added again
     * @param self Storage array containing uint256 type variables
     * @param element the element to add in the array
     */
    function pushValue(Values storage self, uint256 element) internal returns (bool) {
        if (!exists(self, element)) {
            self._items.push(element);
            return true;
        }
        return false;
    }

    /**
     * @notice remove an uint256 from the array
     * @dev finds the element, swaps it with the last element, and then deletes it;
     *      returns a boolean whether the element was found and deleted
     * @param self Storage array containing uint256 type variables
     * @param element the element to remove from the array
     */
    function removeValue(Values storage self, uint256 element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the uint256 at a specific index from array
     * @dev revert if the index is out of bounds
     * @param self Storage array containing uint256 type variables
     * @param index the index in the array
     */
    function getValueAtIndex(Values storage self, uint256 index) internal view returns (uint256) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }

    /**
     * @notice get the size of the array
     * @param self Storage array containing uint256 type variables
     */
    function size(Values storage self) internal view returns (uint256) {
        return self._items.length;
    }

    /**
     * @notice check if an element exist in the array
     * @param self Storage array containing uint256 type variables
     * @param element the element to check if it exists in the array
     */
    function exists(Values storage self, uint256 element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice get the array
     * @param self Storage array containing uint256 type variables
     */
    function getAllValues(Values storage self) internal view returns(uint256[] memory) {
        return self._items;
    }

}
