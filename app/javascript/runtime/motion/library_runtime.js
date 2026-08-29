import { motionBackend } from "platform/motion/motion_backend"
import { MotionDirector } from "runtime/motion/motion_director"

export const libraryMotionDirector = new MotionDirector({ backend: motionBackend })
