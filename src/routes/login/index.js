/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import LayoutContainer from '../../components/Layout/LayoutContainer';
import renderIfLoggedOut from '../helpers/renderIfLoggedOut';
import LoginContainer from './LoginContainer';

function action(context) {
  const state = context.store.getState();

  const subdomain = context.subdomain;
  const next = context.query.next;

  return renderIfLoggedOut(state, () => ({
    chunks: ['login'],
    component: (
      <LayoutContainer path={context.pathname}>
        <LoginContainer team={subdomain} next={next} />
      </LayoutContainer>
    ),
  }));
}

export default action;
