
import React, { PropTypes, Component } from 'react';
import { NativeModules, requireNativeComponent, processColor } from 'react-native';
import resolveAssetSource from 'react-native/Libraries/Image/resolveAssetSource';

const POINTER_EVENTS = 'box-none'

const debounce = function(fn, timeout) {
  let bounceTimer = null
  const clearBounceTimer = (...args) => {
    bounceTimer = setTimeout(() => {
      fn(...args)
      bounceTimer = null
    }, timeout)
  }
  return function(...args) {
    if (!bounceTimer) {
      fn(...args)
      clearBounceTimer(...args)
    } else {
      clearTimeout(bounceTimer)
      clearBounceTimer(...args)
    }
  }
}

export default class VisualSeekBarView extends Component {
  static propTypes = {
    source: PropTypes.oneOfType([PropTypes.string, PropTypes.object, PropTypes.number]).isRequired,
    width: PropTypes.number,
    height: PropTypes.number,
    themeColor: PropTypes.string,
    onTrackerMove: PropTypes.func,
    currentTime: PropTypes.number,
    trackerColor: PropTypes.string,
    trackerHeadColor: PropTypes.string,
    timeColor: PropTypes.string,
  };

  static defaultProps = {
    themeColor: 'gray',
    trackerColor: 'black',
    trackerHeadColor: 'rgba(0,0,0,0)',
    timeColor: 'white',
  };

  constructor(props) {
    super(props);
    const {
      themeColor,
      trackerColor,
      trackerHeadColor,
      timeColor,
      source
    } = props;
    this.state = {
      movingTracker: false,
      source: this.createSource(source)
    };
    this._handleTrackerMove = this._handleTrackerMove.bind(this);
    this._themeColor = processColor(themeColor).toString();
    this._trackerColor = processColor(trackerColor).toString();
    this._trackerHeadColor = processColor(trackerHeadColor).toString();
    this._timeColor = processColor(timeColor).toString();
  }

  componentWillMount() {
    const { onTrackerMove } = this.props;
    this._debounceUnlockTracker = debounce(() => {
      this.setState({ movingTracker: false })
    }, 500)
    this._debounceOnTrackerMove = debounce(({ currentTime }) => {
      onTrackerMove({ currentTime })
    }, 200)
  }

  createSource = (_source) => {
    const source = resolveAssetSource(_source) || {};

    let uri = source.uri || '';
    if (uri && uri.match(/^\//)) {
      uri = `file://${uri}`;
    }
    return {uri}
  }

  shouldComponentUpdate(nextProps, nextState) {
    const { movingTracker } = nextState
    return !movingTracker
  }

  componentWillReceiveProps(nextProps) {
    const { source } = nextProps
    if (source !== this.props.source) {
      this.setState({ source: this.createSource(source) })
    }
  }

  _handleTrackerMove({ nativeEvent }) {
    const { onTrackerMove } = this.props;
    const { currentTime } = nativeEvent;
    this.setState({ movingTracker: true })
    this._debounceUnlockTracker()
    if (typeof onTrackerMove === 'function') {
      this._debounceOnTrackerMove({ currentTime })
    }
  }

  render() {
    const {
      currentTime,
      width,
      height,
    } = this.props;
    const { source } = this.state
    return (
      <RNVisualSeekBarView
        source={source}
        width={width}
        height={height}
        currentTime={currentTime}
        themeColor={this._themeColor}
        trackerColor={this._trackerColor}
        trackerHeadColor={this._trackerHeadColor}
        timeColor={this._timeColor}
        onTrackerMove={this._handleTrackerMove}
        pointerEvents={POINTER_EVENTS}
      />
    );
  }
}

const RNVisualSeekBarView = requireNativeComponent("RNVisualSeekBarView", VisualSeekBarView);
