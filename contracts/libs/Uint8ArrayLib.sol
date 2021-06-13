/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library Uint8ArrayLib {
    using Uint8ArrayLib for Values;
    struct Values {
        uint8[]  _items;
    }
    function pushValue(Values storage self, uint8 element) internal returns (bool) {
        if (!exists(self, element)) {
            self._items.push(element);
            return true;
        }
        return false;
    }
    function removeValue(Values storage self, uint8 element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }
    function getValueAtIndex(Values storage self, uint8 index) internal view returns (uint8) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }
    function size(Values storage self) internal view returns (uint256) {
        return self._items.length;
    }
    function exists(Values storage self, uint8 element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }
    function getAllValues(Values storage self) internal view returns(uint8[] memory) {
        return self._items;
    }

}
