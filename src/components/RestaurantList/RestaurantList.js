import React, { Component, PropTypes } from 'react';
import FlipMove from 'react-flip-move';
import { Element as ScrollElement } from 'react-scroll';
import withStyles from 'isomorphic-style-loader/lib/withStyles';
import Grid from 'react-bootstrap/lib/Grid';
import RestaurantContainer from '../Restaurant/RestaurantContainer';
import Loading from '../Loading';
import s from './RestaurantList.scss';

class RestaurantList extends Component {
  componentWillUpdate() {
    this.scrollY = window.scrollY;
  }

  componentDidUpdate() {
    // prevent Chrome from scrolling to new position of voted restaurant
    window.scrollTo(0, this.scrollY);
  }

  render() {
    const { ids, restaurantListReady } = this.props;

    if (!restaurantListReady) {
      return <Loading />;
    }

    if (!ids.length) {
      return (
        <div className={s.root}>
          <Grid className={s.welcome}>
            <h2>Welcome to Lunch!</h2>
            <p>
              Get started by adding restaurants! Use the above search box and
              add as many restaurants as you like. Then you and your team can
              start voting!
            </p>
          </Grid>
        </div>
      );
    }

    return (
      <FlipMove typeName="ul" className={s.root} staggerDelayBy={40} staggerDurationBy={40}>
        {ids.map(id => (
          <li key={`restaurantListItem_${id}`}>
            <ScrollElement name={`restaurantListItem_${id}`}>
              <RestaurantContainer
                id={id}
                shouldShowAddTagArea
                shouldShowDropdown
              />
            </ScrollElement>
          </li>
        ))}
      </FlipMove>
    );
  }
}

RestaurantList.propTypes = {
  ids: PropTypes.array.isRequired,
  restaurantListReady: PropTypes.bool.isRequired
};

export default withStyles(s)(RestaurantList);
