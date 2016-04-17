import ActionTypes from './constants/ActionTypes';
import { getRestaurantIds, getRestaurantById } from './selectors/restaurants';
import { getTagIds, getTagById } from './selectors/tags';
import * as schemas from './schemas';
import { normalize, arrayOf } from 'normalizr';
import update from 'react-addons-update';
import uuid from 'node-uuid';

const isFetching = state =>
  Object.assign({}, state, {
    isFetching: true
  });

export const restaurants = new Map([
  [ActionTypes.SORT_RESTAURANTS, state =>
    update(state, {
      items: {
        result: {
          $set: state.items.result.map((id, index) => {
            const item = state.items.entities.restaurants[id];
            item.sortIndex = index;
            return item;
          }).sort((a, b) => {
            // stable sort
            if (a.votes.length !== b.votes.length) { return b.votes.length - a.votes.length; }
            return a.sortIndex - b.sortIndex;
          }).map(item => item.id)
        }
      }
    })
  ],
  [ActionTypes.INVALIDATE_RESTAURANTS, state =>
    Object.assign({}, state, {
      didInvalidate: true
    })
  ],
  [ActionTypes.REQUEST_RESTAURANTS, state =>
    Object.assign({}, state, {
      isFetching: true,
      didInvalidate: false
    })
  ],
  [ActionTypes.RECEIVE_RESTAURANTS, (state, action) =>
    Object.assign({}, state, {
      isFetching: false,
      didInvalidate: false,
      items: normalize(action.items, arrayOf(schemas.restaurant))
    })
  ],
  [ActionTypes.POST_RESTAURANT, isFetching],
  [ActionTypes.RESTAURANT_POSTED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $unshift: [action.restaurant.id]
        },
        entities: {
          restaurants: {
            $merge: {
              [action.restaurant.id]: action.restaurant
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETE_RESTAURANT, isFetching],
  [ActionTypes.RESTAURANT_DELETED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $splice: [[getRestaurantIds({ restaurants: state }).indexOf(action.id), 1]]
        }
      }
    })
  ],
  [ActionTypes.RENAME_RESTAURANT, isFetching],
  [ActionTypes.RESTAURANT_RENAMED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          [action.id]: {
            $merge: action.fields
          }
        }
      }
    })
  ],
  [ActionTypes.POST_VOTE, isFetching],
  [ActionTypes.VOTE_POSTED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.vote.restaurant_id]: {
              votes: {
                $push: [action.vote.id]
              }
            }
          },
          votes: {
            $merge: {
              [action.vote.id]: action.vote
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETE_VOTE, isFetching],
  [ActionTypes.VOTE_DELETED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              votes: {
                $splice: [[getRestaurantById({ restaurants: state }, action.restaurantId).votes.indexOf(action.id), 1]]
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.POST_NEW_TAG_TO_RESTAURANT, isFetching],
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              tags: {
                $push: [action.tag.id]
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.POST_TAG_TO_RESTAURANT, isFetching],
  [ActionTypes.POSTED_TAG_TO_RESTAURANT, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              tags: {
                $push: [action.id]
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETE_TAG_FROM_RESTAURANT, isFetching],
  [ActionTypes.DELETED_TAG_FROM_RESTAURANT, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          restaurants: {
            [action.restaurantId]: {
              tags: {
                $splice: [[getRestaurantById({ restaurants: state }, action.restaurantId).tags.indexOf(action.id), 1]]
              }
            }
          }
        }
      }
    })
  ]
]);

export const flashes = new Map([
  [ActionTypes.FLASH_ERROR, (state, action) =>
    [
      ...state,
      {
        message: action.message,
        type: 'error'
      }
    ]
  ],
  [ActionTypes.EXPIRE_FLASH, (state, action) =>
    Array.from(state).splice(action.id, 1)
  ]
]);

export const notifications = new Map([
  [ActionTypes.NOTIFY, (state, action) => {
    const { realAction } = action;
    const notification = {
      actionType: realAction.type,
      id: uuid.v1()
    };
    switch (notification.actionType) {
      case ActionTypes.RESTAURANT_POSTED: {
        const { userId, restaurant } = realAction;
        notification.vals = {
          userId,
          restaurant,
          restaurantId: restaurant.id
        };
        break;
      }
      case ActionTypes.RESTAURANT_DELETED: {
        const { userId, id } = realAction;
        notification.vals = {
          userId,
          restaurantId: id
        };
        break;
      }
      case ActionTypes.RESTAURANT_RENAMED: {
        const { id, fields, userId } = realAction;
        notification.vals = {
          userId,
          restaurantId: id,
          newName: fields.name
        };
        break;
      }
      case ActionTypes.VOTE_POSTED: {
        notification.vals = {
          userId: realAction.vote.user_id,
          restaurantId: realAction.vote.restaurant_id
        };
        break;
      }
      case ActionTypes.VOTE_DELETED: {
        const { userId, restaurantId } = realAction;
        notification.vals = {
          userId,
          restaurantId
        };
        break;
      }
      case ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT: {
        const { userId, restaurantId, tag } = realAction;
        notification.vals = {
          userId,
          restaurantId,
          tag
        };
        break;
      }
      case ActionTypes.POSTED_TAG_TO_RESTAURANT: {
        const { userId, restaurantId, id } = realAction;
        notification.vals = {
          userId,
          restaurantId,
          tagId: id
        };
        break;
      }
      case ActionTypes.DELETED_TAG_FROM_RESTAURANT: {
        const { userId, restaurantId, id } = realAction;
        notification.vals = {
          userId,
          restaurantId,
          tagId: id
        };
        break;
      }
      case ActionTypes.TAG_DELETED: {
        const { userId, id } = realAction;
        notification.vals = {
          userId,
          tagId: id
        };
        break;
      }
      default: {
        return state;
      }
    }
    return [
      ...state.slice(-3),
      notification
    ];
  }],
  [ActionTypes.EXPIRE_NOTIFICATION, (state, action) =>
    state.filter(n => n.id !== action.id)
  ]
]);

const resetRestaurant = (state, action) =>
  Object.assign({}, state, {
    [action.id]: undefined
  });

const resetAddTagAutosuggestValue = (state, action) =>
  Object.assign({}, state, {
    [action.restaurantId]: Object.assign({}, state[action.restaurantId], { addTagAutosuggestValue: '' })
  });

export const listUi = new Map([
  [ActionTypes.RECEIVE_RESTAURANTS, () => {}],
  [ActionTypes.RESTAURANT_RENAMED, resetRestaurant],
  [ActionTypes.RESTAURANT_POSTED, resetRestaurant],
  [ActionTypes.RESTAURANT_DELETED, resetRestaurant],
  [ActionTypes.POSTED_TAG_TO_RESTAURANT, resetAddTagAutosuggestValue],
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT, resetAddTagAutosuggestValue],
  [ActionTypes.SET_ADD_TAG_AUTOSUGGEST_VALUE, (state, action) =>
    Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { addTagAutosuggestValue: action.value })
    })
  ],
  [ActionTypes.SHOW_ADD_TAG_FORM, (state, action) =>
    Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { isAddingTags: true })
    })
  ],
  [ActionTypes.HIDE_ADD_TAG_FORM, (state, action) =>
    Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { isAddingTags: false })
    })
  ],
  [ActionTypes.SET_EDIT_NAME_FORM_VALUE, (state, action) =>
    Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { editNameFormValue: action.value })
    })
  ],
  [ActionTypes.SHOW_EDIT_NAME_FORM, (state, action) =>
    Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { isEditingName: true })
    })
  ],
  [ActionTypes.HIDE_EDIT_NAME_FORM, (state, action) =>
    Object.assign({}, state, {
      [action.id]: Object.assign({}, state[action.id], { isEditingName: false })
    })
  ]
]);

export const mapUi = new Map([
  [ActionTypes.RECEIVE_RESTAURANTS, () =>
    ({
      markers: {},
      showUnvoted: true
    })
  ],
  [ActionTypes.RESTAURANT_POSTED, resetRestaurant],
  [ActionTypes.RESTAURANT_DELETED, resetRestaurant],
  [ActionTypes.SHOW_INFO_WINDOW, (state, action) =>
    Object.assign({}, state, {
      markers: Object.assign({}, state.markers, {
        [action.id]: Object.assign({}, state[action.id], { showInfoWindow: true })
      })
    })
  ],
  [ActionTypes.HIDE_INFO_WINDOW, (state, action) =>
    Object.assign({}, state, {
      markers: Object.assign({}, state.markers, {
        [action.id]: Object.assign({}, state[action.id], { showInfoWindow: false })
      })
    })
  ],
  [ActionTypes.SET_SHOW_UNVOTED, (state, action) =>
    Object.assign({}, state, {
      showUnvoted: action.val
    })
  ]
]);

export const pageUi = new Map([
  [ActionTypes.SCROLL_TO_TOP, state =>
    Object.assign({}, state, {
      shouldScrollToTop: true
    })
  ],
  [ActionTypes.SCROLLED_TO_TOP, state =>
    Object.assign({}, state, {
      shouldScrollToTop: false
    })
  ],
]);

export const modals = new Map([
  [ActionTypes.SHOW_MODAL, (state, action) =>
    update(state, {
      $merge: {
        [action.name]: {
          shown: true,
          ...action.opts
        }
      }
    })
  ],
  [ActionTypes.HIDE_MODAL, (state, action) =>
    Object.assign({}, state, {
      [action.name]: Object.assign({}, state[action.name], { shown: false })
    })
  ],
  [ActionTypes.RESTAURANT_DELETED, state =>
    Object.assign({}, state, {
      deleteRestaurant: Object.assign({}, state.deleteRestaurant, { shown: false })
    })
  ],
  [ActionTypes.TAG_DELETED, state =>
    Object.assign({}, state, {
      deleteTag: Object.assign({}, state.deleteTag, { shown: false })
    })
  ]
]);

export const tags = new Map([
  [ActionTypes.POSTED_TAG_TO_RESTAURANT, (state, action) =>
    update(state, {
      items: {
        entities: {
          tags: {
            [action.id]: {
              restaurant_count: {
                $set: parseInt(getTagById({ tags: state }, action.id).restaurant_count, 10) + 1
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.POSTED_NEW_TAG_TO_RESTAURANT, (state, action) =>
    update(state, {
      items: {
        result: {
          $push: [action.tag.id]
        },
        entities: {
          tags: {
            $merge: {
              [action.tag.id]: action.tag
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETED_TAG_FROM_RESTAURANT, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        entities: {
          tags: {
            [action.id]: {
              $merge: {
                restaurant_count:
                  parseInt(state.items.entities.tags[action.id].restaurant_count, 10) - 1
              }
            }
          }
        }
      }
    })
  ],
  [ActionTypes.DELETE_TAG, isFetching],
  [ActionTypes.TAG_DELETED, (state, action) =>
    update(state, {
      isFetching: {
        $set: false
      },
      items: {
        result: {
          $splice: [[getTagIds({ tags: state }).indexOf(action.id), 1]]
        }
      }
    })
  ]
]);

export const tagUi = new Map([
  [ActionTypes.SHOW_TAG_FILTER_FORM, state =>
    Object.assign({}, state, {
      filterFormShown: true
    })
  ],
  [ActionTypes.HIDE_TAG_FILTER_FORM, state =>
    Object.assign({}, state, {
      autosuggestValue: '',
      filterFormShown: false
    })
  ],
  [ActionTypes.SET_TAG_FILTER_AUTOSUGGEST_VALUE, (state, action) =>
    Object.assign({}, state, {
      autosuggestValue: action.value
    })
  ],
  [ActionTypes.ADD_TAG_FILTER, state =>
    Object.assign({}, state, {
      autosuggestValue: ''
    })
  ]
]);

export const tagFilters = new Map([
  [ActionTypes.ADD_TAG_FILTER, (state, action) =>
    [
      ...state,
      action.id
    ]
  ],
  [ActionTypes.REMOVE_TAG_FILTER, (state, action) =>
    state.filter(tagFilter => tagFilter !== action.id)
  ],
  [ActionTypes.HIDE_TAG_FILTER_FORM, () => []]
]);

export const latLng = new Map();
export const user = new Map();
export const users = new Map();
export const wsPort = new Map();