package expo.modules.roomplan

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout

class RoomPlanView @JvmOverloads constructor(
  context: Context,
  attrs: AttributeSet? = null,
  defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

  init {
    // Fail fast: RoomPlan is iOS-only.
    throw UnsupportedOperationException("RoomPlan SDK is not available on Android.")
  }
}
