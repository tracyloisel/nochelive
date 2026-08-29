import { nativeMotionBackend } from "platform/motion/native_backend"
import { MotionDirector } from "runtime/motion/motion_director"

export const motionDirector = new MotionDirector({ backend: nativeMotionBackend })
