/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React, { Component, PropTypes } from 'react';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import LoginContainer from '../Login/LoginContainer';
import FlashContainer from '../Flash/FlashContainer';
import MenuContainer from '../Menu/MenuContainer';
import Link from '../Link';
import lunch from './lunch.png';
import s from './Header.scss';

class Header extends Component {
  static propTypes = {
    flashes: PropTypes.array.isRequired,
    loggedIn: PropTypes.bool.isRequired,
    path: PropTypes.string,
    teamSlug: PropTypes.string
  };

  static defaultProps = {
    path: PropTypes.string,
    teamSlug: undefined
  };

  state = {
    menuOpen: false
  };

  componentWillReceiveProps(nextProps) {
    if (!nextProps.path || nextProps.path !== this.props.path) {
      this.setState({
        menuOpen: false
      });
    }
  }

  flashContainers = () => {
    const { flashes } = this.props;

    return flashes.map(
      (flash, i) =>
        <FlashContainer message={flash.message} type={flash.type} id={i} key={`${flash.type}_${flash.message}`} />
    );
  }

  closeMenu = () => {
    this.setState({
      menuOpen: false
    });
  }

  toggleMenu = () => {
    this.setState({
      menuOpen: !this.state.menuOpen
    });
  }

  render() {
    const { loggedIn, teamSlug } = this.props;
    const { menuOpen } = this.state;
    return (
      <div className={`${s.root} ${loggedIn ? s.loggedIn : ''}`}>
        <div className={s.background} />
        <div className={s.flashes}>
          {this.flashContainers()}
        </div>
        <div className={s.container}>
          <div className={s.banner}>
            <h1 className={s.bannerTitle}>
              <Link to={teamSlug ? `/teams/${teamSlug}` : '/'}>
                <img src={lunch} alt="Lunch" />
              </Link>
            </h1>
          </div>
        </div>
        {loggedIn ?
          <div>
            <button className={s.hamburger} onClick={this.toggleMenu}>
              <span>Menu</span>
            </button>
            {menuOpen && <button className={s.menuBackground} onClick={this.closeMenu} />}
            <MenuContainer open={menuOpen} teamSlug={teamSlug} closeMenu={this.closeMenu} />
          </div>
          :
          <LoginContainer />
        }
      </div>
    );
  }
}

export default withStyles(s)(Header);
