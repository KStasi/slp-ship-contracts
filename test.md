## Test Item: Factory

### General Requirements:

1. The factory is used for Wrapped slp tokens deployment.
2. Anyone can deploy new wrapped slp token contract for the original slp.
3. Wrapped slp token is deployed only if there is no contract with the same original slp address.
4. The new wrapped slp should be controlled by the Factory owner.

**Scope**: Test the deployment permissions.

**Action**: Invoke `createWslp` on Factory contract.

**Test Notes and Preconditions**: -

**Verification Steps**: Verify the deployment can be done by anyone.

**Scenario 1**: Test deployment by:

- [ ] owner
- [ ] unprevileged user

**Scope**: Test the number of wrapped slp contracts per one slp.

**Action**: Invoke `createWslp` on Factory contract.

**Test Notes and Preconditions**: -

**Verification Steps**: Verify the deployment of the Wrapped slp can be done only once for the particular token.

**Scenario 1**: Test deployment of the wrapped slp:

- [ ] in the first time for slp token A
- [ ] in the second times for slp token A

## Test Item: WrappedSLP

### General Requirements:

1. The WrappedSLP represents the SLP asset.
2. Only owner can mint new tokens.
3. Anyone can burn tokens.
4. The of ~1% per year is charged from the WSLP holders.
5. The owner can burn fees.
6. The tokens transfer can be canceled by the owner after the user's request.

**Scope**: Test the deployment permissions.

**Action**: Invoke `deposit` on Factory contract.

**Test Notes and Preconditions**: -

**Verification Steps**: Verify the new tokens can be minter only by the owner.

**Scenario 1**: Test deposit:

- [ ] owner
- [ ] unprevileged user
