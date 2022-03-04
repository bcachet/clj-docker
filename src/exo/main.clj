(ns exo.main
  (:require [exo.add :refer [sum]])
  (:gen-class))

(defn -main
  [& args]
  (println (apply sum (map bigdec args)))
  (System/exit 0))