import { connect } from 'react-redux';
import App from '../components/App';

const mapStateToProps = null;

const mapDispatchToProps = dispatch => ({
  messageReceived(event) {
    try {
      const data = JSON.parse(event.data);
      dispatch(data);
    } catch (SyntaxError) {
      console.error('Couldn\'t parse message data.');
    }
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(App);