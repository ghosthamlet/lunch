/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable global-require */

// The top-level (parent) route
export default {

  path: '/',

  // Keep in mind, routes are evaluated in order
  children: [
    require('./landing').default,
    require('./newTeam').default,
    {
      path: '/teams',
      children: [
        require('./teams').default,
        require('./teams/team').default
      ]
    },

    // Wildcard routes, e.g. { path: '*', ... } (must go last)
    require('./notFound').default,
  ],

  async action({ next }) {
    // Execute each child route until one of them return the result
    const route = await next(true);

    // Provide default values for title, description etc.
    const title = 'Lunch';
    if (route.title) {
      route.title = `${title} | ${route.title}`;
    } else {
      route.title = title;
    }
    route.description = route.description || '';

    return route;
  },

};
